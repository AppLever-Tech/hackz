import 'package:firebase_core/firebase_core.dart';

import 'hackz_firebase.dart';

/// Approved tenant Firebase projects. Only Control Plane catalog entries may
/// become tenants — never trust options or project ids supplied by a user.
abstract final class ApprovedTenantFirebase {
  ApprovedTenantFirebase._();

  static String get controlPlaneProjectId {
    return HackzFirebase.controlPlane.context.firebaseOptions.projectId;
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
