import 'package:firebase_core/firebase_core.dart';

import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/hackz_provisioning_identity.dart';
import '../../../../core/firebase/tenant_connection_exception.dart';
import '../../../../core/firebase/tenant_firebase.dart';
import 'tenant_workspace_validator.dart';

/// Authorization checks for the College Controls Authorization step.
///
/// Does not create College Admin users or other business data. Does not probe Storage.
abstract final class ProvisioningAuthorizationValidator {
  ProvisioningAuthorizationValidator._();

  static Future<List<TenantWorkspaceCheck>> validate(String firebaseProjectId) async {
    final String projectId = firebaseProjectId.trim();
    final HackzProvisioningIdentity identity = await HackzProvisioningIdentity.load();
    final TenantWorkspaceCheck identityCheck = TenantWorkspaceCheck(
      id: 'identity',
      label: 'Hackz provisioning identity',
      ok: identity.serviceAccountEmail.contains('@'),
      detail: identity.serviceAccountEmail.contains('@')
          ? 'College grants ${identity.serviceAccountEmail} on this project.'
          : 'Set the Hackz provisioning service account on Control Plane.',
    );

    if (!ApprovedTenantFirebase.isApproved(projectId)) {
      return <TenantWorkspaceCheck>[
        const TenantWorkspaceCheck(
          id: 'project',
          label: 'Tenant Firebase project',
          ok: false,
          detail: 'Choose an approved Hackz workspace.',
        ),
        identityCheck,
        const TenantWorkspaceCheck(id: 'auth', label: 'Firebase Authentication', ok: false),
        const TenantWorkspaceCheck(id: 'firestore', label: 'Firestore', ok: false),
      ];
    }

    final FirebaseApp app;
    try {
      app = await TenantFirebase.openApprovedWorkspace(projectId);
    } on TenantConnectionException catch (e) {
      return <TenantWorkspaceCheck>[
        TenantWorkspaceCheck(
          id: 'project',
          label: 'Tenant Firebase project',
          ok: false,
          detail: e.message,
        ),
        identityCheck,
        const TenantWorkspaceCheck(id: 'auth', label: 'Firebase Authentication', ok: false),
        const TenantWorkspaceCheck(id: 'firestore', label: 'Firestore', ok: false),
      ];
    } catch (_) {
      return <TenantWorkspaceCheck>[
        const TenantWorkspaceCheck(
          id: 'project',
          label: 'Tenant Firebase project',
          ok: false,
          detail: 'Unable to reach this Firebase project.',
        ),
        identityCheck,
        const TenantWorkspaceCheck(id: 'auth', label: 'Firebase Authentication', ok: false),
        const TenantWorkspaceCheck(id: 'firestore', label: 'Firestore', ok: false),
      ];
    }

    final ({bool authOk, bool firestoreOk}) ping = await TenantFirebase.pingAuthAndFirestore(app);
    return <TenantWorkspaceCheck>[
      TenantWorkspaceCheck(
        id: 'project',
        label: 'Tenant Firebase project',
        ok: true,
        detail: '$projectId is reachable. The college remains the project owner.',
      ),
      identityCheck,
      TenantWorkspaceCheck(
        id: 'auth',
        label: 'Firebase Authentication',
        ok: ping.authOk,
        detail: ping.authOk
            ? 'Authentication on this project can be reached for provisioning.'
            : 'Authentication on this project is not responding.',
      ),
      TenantWorkspaceCheck(
        id: 'firestore',
        label: 'Firestore',
        ok: ping.firestoreOk,
        detail: ping.firestoreOk
            ? 'Firestore on this project can be reached for provisioning. No data was written.'
            : 'Firestore on this project is not responding.',
      ),
    ];
  }

  static bool allPassed(Iterable<TenantWorkspaceCheck> checks) {
    return checks.isNotEmpty && checks.every((TenantWorkspaceCheck check) => check.ok);
  }
}
