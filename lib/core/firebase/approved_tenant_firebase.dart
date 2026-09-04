import 'package:firebase_core/firebase_core.dart';

import 'hackz_firebase.dart';

/// An approved tenant workspace. Only Control Plane catalog entries may become tenants.
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

/// Approved tenant Firebase projects. Never trust options or project ids supplied by a user.
abstract final class ApprovedTenantFirebase {
  ApprovedTenantFirebase._();

  static String get controlPlaneProjectId {
    return HackzFirebase.controlPlane.context.firebaseOptions.projectId;
  }

  /// Workspaces Hackz Admin may connect a college to.
  static List<ApprovedTenantWorkspace> get workspaces {
    return <ApprovedTenantWorkspace>[
      ApprovedTenantWorkspace(
        projectId: controlPlaneProjectId,
        label: 'Hackz hosted workspace',
        subtitle: 'Approved platform workspace for this organisation.',
      ),
    ];
  }

  static ApprovedTenantWorkspace? workspaceFor(String projectId) {
    final String id = projectId.trim();
    for (final ApprovedTenantWorkspace workspace in workspaces) {
      if (workspace.projectId == id) return workspace;
    }
    return null;
  }

  /// Options for an approved [projectId], or `null` if the project is not
  /// registered in the Control Plane catalog.
  static FirebaseOptions? optionsFor(String projectId) {
    final String id = projectId.trim();
    if (id.isEmpty) return null;
    final FirebaseOptions controlPlane = HackzFirebase.controlPlane.context.firebaseOptions;
    if (id == controlPlane.projectId) return controlPlane;
    return null;
  }

  static bool isApproved(String projectId) => optionsFor(projectId) != null;
}
