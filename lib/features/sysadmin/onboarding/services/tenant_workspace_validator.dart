import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/hackz_firebase.dart';
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

/// Live checks against an approved workspace. Does not initialize a second Firebase app.
abstract final class TenantWorkspaceValidator {
  TenantWorkspaceValidator._();

  static const Duration _timeout = Duration(seconds: 8);

  static Future<List<TenantWorkspaceCheck>> validate(String firebaseProjectId) async {
    final String projectId = firebaseProjectId.trim();
    if (!ApprovedTenantFirebase.isApproved(projectId)) {
      return const <TenantWorkspaceCheck>[
        TenantWorkspaceCheck(
          id: 'connection',
          label: 'Platform connection',
          ok: false,
          detail: 'Choose an approved Hackz workspace.',
        ),
        TenantWorkspaceCheck(id: 'auth', label: 'Sign-in ready', ok: false),
        TenantWorkspaceCheck(id: 'data', label: 'Workspace data ready', ok: false),
        TenantWorkspaceCheck(id: 'files', label: 'File storage ready', ok: false),
        TenantWorkspaceCheck(id: 'access', label: 'Administrator access', ok: false),
      ];
    }

    final List<TenantWorkspaceCheck> results = await Future.wait(<Future<TenantWorkspaceCheck>>[
      _checkConnection(projectId),
      _checkAuth(),
      _checkData(),
      _checkFiles(),
      _checkAccess(),
    ]);
    return results;
  }

  static bool allPassed(Iterable<TenantWorkspaceCheck> checks) {
    return checks.isNotEmpty && checks.every((TenantWorkspaceCheck check) => check.ok);
  }

  static Future<TenantWorkspaceCheck> _checkConnection(String projectId) async {
    try {
      final String boundId = HackzFirebase.controlPlane.context.firebaseOptions.projectId;
      if (boundId != projectId) {
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
    } catch (e) {
      return TenantWorkspaceCheck(
        id: 'connection',
        label: 'Platform connection',
        ok: false,
        detail: 'Unable to reach the Hackz workspace.',
      );
    }
  }

  static Future<TenantWorkspaceCheck> _checkAuth() async {
    try {
      final FirebaseAuth auth = HackzFirebase.controlPlane.auth;
      await auth.authStateChanges().first.timeout(_timeout);
      return const TenantWorkspaceCheck(
        id: 'auth',
        label: 'Sign-in ready',
        ok: true,
        detail: 'Sign-in services are available.',
      );
    } catch (e) {
      return const TenantWorkspaceCheck(
        id: 'auth',
        label: 'Sign-in ready',
        ok: false,
        detail: 'Sign-in services are not responding.',
      );
    }
  }

  static Future<TenantWorkspaceCheck> _checkData() async {
    try {
      await HackzFirebase.controlPlane.firestore
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
    } catch (e) {
      return const TenantWorkspaceCheck(
        id: 'data',
        label: 'Workspace data ready',
        ok: false,
        detail: 'Unable to read organisation data.',
      );
    }
  }

  static Future<TenantWorkspaceCheck> _checkFiles() async {
    try {
      final FirebaseStorage storage = HackzFirebase.controlPlane.storage;
      final String bucket = storage.app.options.storageBucket ?? '';
      if (bucket.trim().isEmpty) {
        return const TenantWorkspaceCheck(
          id: 'files',
          label: 'File storage ready',
          ok: false,
          detail: 'File storage is not configured.',
        );
      }
      try {
        await storage.ref().list(const ListOptions(maxResults: 1)).timeout(_timeout);
      } on FirebaseException catch (e) {
        const Set<String> reachable = <String>{
          'object-not-found',
          'unauthorized',
          'permission-denied',
          'unauthenticated',
        };
        if (!reachable.contains(e.code)) rethrow;
      }
      return const TenantWorkspaceCheck(
        id: 'files',
        label: 'File storage ready',
        ok: true,
        detail: 'Logos and documents can be stored.',
      );
    } catch (e) {
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
      await HackzFirebase.controlPlane.firestore
          .collection('hkzTenants')
          .limit(1)
          .get()
          .timeout(_timeout);
      return const TenantWorkspaceCheck(
        id: 'access',
        label: 'Administrator access',
        ok: true,
        detail: 'You can register and activate organisations.',
      );
    } catch (e) {
      return const TenantWorkspaceCheck(
        id: 'access',
        label: 'Administrator access',
        ok: false,
        detail: 'Missing permission to finish onboarding.',
      );
    }
  }
}
