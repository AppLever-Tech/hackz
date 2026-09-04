import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'approved_tenant_project.dart';
import 'hackz_firebase.dart';

/// An approved tenant workspace shown to Hackz Admin during onboarding.
class ApprovedTenantWorkspace {
  const ApprovedTenantWorkspace({
    required this.projectId,
    required this.label,
    required this.subtitle,
  });

  final String projectId;
  final String label;
  final String subtitle;
}

/// Approved tenant Firebase projects. Only Control Plane catalog entries may
/// become tenants — never trust options or project ids supplied by a user.
abstract final class ApprovedTenantFirebase {
  ApprovedTenantFirebase._();

  static const String collectionName = 'hkzApprovedFirebaseProjects';

  static final Map<String, ApprovedTenantProject> _catalog = <String, ApprovedTenantProject>{};

  static FirebaseFirestore get _db => HackzFirebase.controlPlane.firestore;

  static String get controlPlaneProjectId {
    return HackzFirebase.controlPlane.context.firebaseOptions.projectId;
  }

  static CollectionReference<Map<String, dynamic>> get _col {
    return _db.collection(collectionName);
  }

  /// Workspaces Hackz Admin may connect a college to (Control Plane + catalog).
  static List<ApprovedTenantWorkspace> get workspaces {
    final Map<String, ApprovedTenantWorkspace> byId = <String, ApprovedTenantWorkspace>{
      controlPlaneProjectId: ApprovedTenantWorkspace(
        projectId: controlPlaneProjectId,
        label: 'Hackz hosted workspace',
        subtitle: 'Approved platform workspace for this organisation.',
      ),
    };
    for (final ApprovedTenantProject project in _catalog.values) {
      if (project.projectId.isEmpty) continue;
      byId.putIfAbsent(
        project.projectId,
        () => ApprovedTenantWorkspace(
          projectId: project.projectId,
          label: project.label.isEmpty ? project.projectId : project.label,
          subtitle: project.subtitle,
        ),
      );
    }
    return byId.values.toList(growable: false);
  }

  static ApprovedTenantWorkspace? workspaceFor(String projectId) {
    final String id = projectId.trim();
    for (final ApprovedTenantWorkspace workspace in workspaces) {
      if (workspace.projectId == id) return workspace;
    }
    return null;
  }

  /// Options for an approved [projectId], or `null` if not in the catalog.
  static FirebaseOptions? optionsFor(String projectId) {
    final String id = projectId.trim();
    if (id.isEmpty) return null;
    final FirebaseOptions controlPlane = HackzFirebase.controlPlane.context.firebaseOptions;
    if (id == controlPlane.projectId) return controlPlane;
    final ApprovedTenantProject? registered = _catalog[id];
    if (registered == null) return null;
    return registered.optionsForCurrentPlatform;
  }

  static bool isApproved(String projectId) => optionsFor(projectId) != null;

  static Future<void> refresh() async {
    _rememberControlPlane();
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _col.get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final ApprovedTenantProject project = ApprovedTenantProject.fromMap(doc.id, doc.data());
        if (project.projectId.isEmpty || project.apiKey.isEmpty) continue;
        _catalog[project.projectId] = project;
      }
    } catch (_) {
      // Control Plane project remains approved even if the catalog cannot load.
    }
  }

  static Future<void> register(ApprovedTenantProject project) async {
    final String id = project.projectId.trim();
    if (id.isEmpty || project.apiKey.trim().isEmpty) {
      throw ArgumentError('Workspace connection details are incomplete.');
    }
    if ((project.appIdWeb.trim().isEmpty) && (project.appIdAndroid.trim().isEmpty)) {
      throw ArgumentError('Workspace connection details are incomplete.');
    }
    if (project.messagingSenderId.trim().isEmpty || project.storageBucket.trim().isEmpty) {
      throw ArgumentError('Workspace connection details are incomplete.');
    }
    await _col.doc(id).set(project.toMap(), SetOptions(merge: true));
    _catalog[id] = project;
  }

  static void _rememberControlPlane() {
    final FirebaseOptions options = HackzFirebase.controlPlane.context.firebaseOptions;
    _catalog.putIfAbsent(
      options.projectId,
      () => ApprovedTenantProject.fromFirebaseOptions(
        options: options,
        label: 'Hackz hosted workspace',
      ),
    );
  }
}
