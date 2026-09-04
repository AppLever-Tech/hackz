import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../core/firebase/tenant_connection_exception.dart';
import '../../../../core/firebase/tenant_firebase.dart';
import '../../../../utils/firestore_utils.dart';

class TenantWorkspaceCheck {
  const TenantWorkspaceCheck({
    required this.id,
    required this.label,
    required this.ok,
    this.detail = '',
  });

  final String id;
  final String label;
  final bool ok;
  final String detail;
}

typedef TenantWorkspaceCheckProgress = void Function(String message, double progress);

/// Live checks against an approved workspace. Does not bind [HackzFirebase.current].
abstract final class TenantWorkspaceValidator {
  TenantWorkspaceValidator._();

  static const Duration _timeout = Duration(seconds: 8);

  static Future<List<TenantWorkspaceCheck>> validate(
    String firebaseProjectId, {
    TenantWorkspaceCheckProgress? onProgress,
  }) async {
    final String projectId = firebaseProjectId.trim();
    if (!ApprovedTenantFirebase.isApproved(projectId)) {
      return _failed(
        connectionDetail: 'Choose an approved Hackz workspace.',
      );
    }

    onProgress?.call('Opening the workspace...', 0.1);
    final FirebaseApp app;
    try {
      app = await TenantFirebase.openApprovedWorkspace(projectId);
    } on TenantConnectionException catch (e) {
      return _failed(connectionDetail: e.message);
    } catch (_) {
      return _failed(connectionDetail: 'Unable to reach the Hackz workspace.');
    }

    final List<({String message, Future<TenantWorkspaceCheck> Function() run})> steps =
        <({String message, Future<TenantWorkspaceCheck> Function() run})>[
      (
        message: 'Checking platform connection...',
        run: () => _checkConnection(projectId, app),
      ),
      (
        message: 'Checking sign-in services...',
        run: () => _checkAuth(app),
      ),
      (
        message: 'Checking workspace data...',
        run: () => _checkData(app),
      ),
      (
        message: 'Checking file storage...',
        run: () => _checkFiles(app),
      ),
      (
        message: 'Checking administrator access...',
        run: () => _checkAccess(),
      ),
    ];

    final List<TenantWorkspaceCheck> results = <TenantWorkspaceCheck>[];
    for (int i = 0; i < steps.length; i++) {
      final double progress = (i + 1) / (steps.length + 1);
      onProgress?.call(steps[i].message, progress);
      results.add(await steps[i].run());
    }
    onProgress?.call('Finishing checks...', 1);
    return results;
  }

  static bool allPassed(Iterable<TenantWorkspaceCheck> checks) {
    return checks.isNotEmpty && checks.every((TenantWorkspaceCheck check) => check.ok);
  }

  static List<TenantWorkspaceCheck> _failed({required String connectionDetail}) {
    return <TenantWorkspaceCheck>[
      TenantWorkspaceCheck(
        id: 'connection',
        label: 'Platform connection',
        ok: false,
        detail: connectionDetail,
      ),
      const TenantWorkspaceCheck(id: 'auth', label: 'Sign-in ready', ok: false),
      const TenantWorkspaceCheck(id: 'data', label: 'Workspace data ready', ok: false),
      const TenantWorkspaceCheck(id: 'files', label: 'File storage ready', ok: false),
      const TenantWorkspaceCheck(id: 'access', label: 'Administrator access', ok: false),
    ];
  }

  static Future<TenantWorkspaceCheck> _checkConnection(String projectId, FirebaseApp app) async {
    try {
      if (app.options.projectId != projectId) {
        return const TenantWorkspaceCheck(
          id: 'connection',
          label: 'Platform connection',
          ok: false,
          detail: 'That workspace is not the approved Hackz workspace.',
        );
      }
      return const TenantWorkspaceCheck(
        id: 'connection',
        label: 'Platform connection',
        ok: true,
        detail: 'Approved workspace is reachable.',
      );
    } catch (_) {
      return const TenantWorkspaceCheck(
        id: 'connection',
        label: 'Platform connection',
        ok: false,
        detail: 'Unable to reach the Hackz workspace.',
      );
    }
  }

  static Future<TenantWorkspaceCheck> _checkAuth(FirebaseApp app) async {
    try {
      await FirebaseAuth.instanceFor(app: app).authStateChanges().first.timeout(_timeout);
      return const TenantWorkspaceCheck(
        id: 'auth',
        label: 'Sign-in ready',
        ok: true,
        detail: 'Sign-in services are available.',
      );
    } catch (_) {
      return const TenantWorkspaceCheck(
        id: 'auth',
        label: 'Sign-in ready',
        ok: false,
        detail: 'Sign-in services are not responding.',
      );
    }
  }

  static Future<TenantWorkspaceCheck> _checkData(FirebaseApp app) async {
    try {
      await FirebaseFirestore.instanceFor(app: app)
          .collection(FirestoreUtils.hkzOrganizations)
          .limit(1)
          .get()
          .timeout(_timeout);
      return const TenantWorkspaceCheck(
        id: 'data',
        label: 'Workspace data ready',
        ok: true,
        detail: 'Organisation data can be stored.',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return const TenantWorkspaceCheck(
          id: 'data',
          label: 'Workspace data ready',
          ok: false,
          detail: 'Unable to read organisation data.',
        );
      }
      return const TenantWorkspaceCheck(
        id: 'data',
        label: 'Workspace data ready',
        ok: true,
        detail: 'Organisation data can be stored.',
      );
    } catch (_) {
      return const TenantWorkspaceCheck(
        id: 'data',
        label: 'Workspace data ready',
        ok: false,
        detail: 'Unable to read organisation data.',
      );
    }
  }

  static Future<TenantWorkspaceCheck> _checkFiles(FirebaseApp app) async {
    try {
      final String bucket = (app.options.storageBucket ?? '').trim();
      if (bucket.isEmpty) {
        return const TenantWorkspaceCheck(
          id: 'files',
          label: 'File storage ready',
          ok: false,
          detail: 'File storage is not configured.',
        );
      }
      final bool reachable = await TenantFirebase.isStorageReachable(app);
      if (!reachable) {
        return const TenantWorkspaceCheck(
          id: 'files',
          label: 'File storage ready',
          ok: false,
          detail: 'File storage is not responding.',
        );
      }
      return const TenantWorkspaceCheck(
        id: 'files',
        label: 'File storage ready',
        ok: true,
        detail: 'Logos and documents can be stored.',
      );
    } catch (_) {
      return const TenantWorkspaceCheck(
        id: 'files',
        label: 'File storage ready',
        ok: false,
        detail: 'File storage is not responding.',
      );
    }
  }

  static Future<TenantWorkspaceCheck> _checkAccess() async {
    try {
      final User? user = HackzFirebase.controlPlane.auth.currentUser;
      if (user == null) {
        return const TenantWorkspaceCheck(
          id: 'access',
          label: 'Administrator access',
          ok: false,
          detail: 'Sign in as a Hackz administrator to continue.',
        );
      }
      await HackzFirebase.controlPlane.firestore.collection('hkzTenants').limit(1).get().timeout(_timeout);
      return const TenantWorkspaceCheck(
        id: 'access',
        label: 'Administrator access',
        ok: true,
        detail: 'You can register and activate organisations.',
      );
    } catch (_) {
      return const TenantWorkspaceCheck(
        id: 'access',
        label: 'Administrator access',
        ok: false,
        detail: 'Missing permission to finish onboarding.',
      );
    }
  }
}
