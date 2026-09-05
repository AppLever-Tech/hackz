import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'approved_tenant_firebase.dart';
import 'hackz_firebase.dart';
import 'last_organisation_code_store.dart';
import 'tenant_connection_exception.dart';
import 'tenant_context.dart';
import 'tenant_resolver.dart';

class TenantWorkspaceProbe {
  const TenantWorkspaceProbe({
    required this.context,
    required this.authOk,
    required this.firestoreOk,
    required this.storageOk,
  });

  final TenantContext context;
  final bool authOk;
  final bool firestoreOk;
  final bool storageOk;

  bool get ok => authOk && firestoreOk && storageOk;

  String get projectId => context.firebaseOptions.projectId;
}

/// Initializes and binds the Firebase app for a resolved tenant.
///
/// Control Plane stays on [HackzFirebase.controlPlane]. Feature modules keep
/// using [HackzFirebase.current] after [connect].
abstract final class TenantFirebase {
  TenantFirebase._();

  static const String _appPrefix = 'tenant-';

  static String appNameFor({
    required String tenantId,
    required String projectId,
    required String controlPlaneProjectId,
  }) {
    if (projectId.trim() == controlPlaneProjectId.trim()) {
      return defaultFirebaseAppName;
    }
    return '$_appPrefix${tenantId.trim()}';
  }

  /// Opens (or reuses) the Firebase app for approved [options] without binding
  /// [HackzFirebase.current]. Used for onboarding checks and SysAdmin probes.
  static Future<FirebaseApp> ensureApp({
    required String tenantId,
    required FirebaseOptions options,
  }) async {
    final String controlPlaneId = HackzFirebase.controlPlane.context.firebaseOptions.projectId;
    if (options.projectId == controlPlaneId) {
      return HackzFirebase.controlPlane.app;
    }
    final String name = appNameFor(
      tenantId: tenantId,
      projectId: options.projectId,
      controlPlaneProjectId: controlPlaneId,
    );
    try {
      final FirebaseApp existing = Firebase.app(name);
      if (_sameProject(existing.options, options)) return existing;
      await existing.delete();
    } catch (_) {
      // Named app does not exist yet.
    }
    return Firebase.initializeApp(name: name, options: options);
  }

  /// Resolves [organisationCode] from the Control Plane registry, validates the
  /// tenant, initializes its Firebase app, and binds [HackzFirebase.current].
  static Future<TenantContext> connect(
    String organisationCode, {
    bool notifySession = true,
  }) async {
    final TenantContext context = await TenantResolver.resolveByOrganisationCode(organisationCode);
    return _bind(context, notifySession: notifySession);
  }

  /// SysAdmin organisation access: bind tenant data without changing Control Plane Auth.
  static Future<TenantContext> enterAsPlatformAdmin(String tenantId) async {
    if (!HackzFirebase.isPlatformAdminSession) {
      throw const TenantConnectionException(TenantConnectionFailure.unauthorized);
    }
    if (HackzFirebase.controlPlane.auth.currentUser == null) {
      throw const TenantConnectionException(TenantConnectionFailure.unavailable);
    }
    final TenantContext context = await TenantResolver.resolveByTenantId(tenantId);
    return _bind(context, notifySession: false);
  }

  /// Restores Control Plane data binding without signing the SysAdmin out.
  static Future<void> returnToControlPlane() async {
    await disconnect(notifySession: false);
  }

  static Future<TenantContext> _bind(
    TenantContext context, {
    required bool notifySession,
  }) async {
    try {
      final FirebaseApp app = await ensureApp(
        tenantId: context.tenantId,
        options: context.firebaseOptions,
      );
      await _releaseOtherTenantApps(keepName: app.name);
      HackzFirebase.bind(context, app: app, notifySession: notifySession);
      return context;
    } on TenantConnectionException {
      rethrow;
    } catch (_) {
      throw const TenantConnectionException(TenantConnectionFailure.unavailable);
    }
  }

  /// Restores [HackzFirebase.current] to the Control Plane app.
  static Future<void> disconnect({bool notifySession = true}) async {
    await _releaseOtherTenantApps(keepName: HackzFirebase.controlPlane.app.name);
    HackzFirebase.bind(
      HackzFirebase.controlPlane.context,
      app: HackzFirebase.controlPlane.app,
      notifySession: notifySession,
    );
  }

  /// Signs the current Auth user out and restores Control Plane binding.
  ///
  /// Use this when leaving a tenant session (logout / return to landing).
  /// Do not call it between OTP and Sign Up — that flow stays on the tenant.
  static Future<void> releaseSession() async {
    final FirebaseAuth auth = HackzFirebase.isBound
        ? HackzFirebase.sessionAuth
        : HackzFirebase.controlPlane.auth;
    try {
      await auth.signOut();
    } catch (_) {}
    HackzFirebase.endPlatformAdminSession();
    await LastOrganisationCodeStore.clearPlatformAdminSession();
    if (HackzFirebase.isTenantBound) {
      await disconnect();
    }
  }

  /// Validates Auth, Firestore, and Storage on the tenant project without
  /// switching the active session (SysAdmin stays on the Control Plane).
  static Future<TenantWorkspaceProbe> probe(String organisationCode) async {
    final TenantContext context = await TenantResolver.resolveByOrganisationCode(organisationCode);
    try {
      final FirebaseApp app = await ensureApp(
        tenantId: context.tenantId,
        options: context.firebaseOptions,
      );
      final bool authOk = await _pingAuth(app);
      final bool firestoreOk = await _pingFirestore(app);
      final bool storageOk = await _pingStorage(app);
      return TenantWorkspaceProbe(
        context: context,
        authOk: authOk,
        firestoreOk: firestoreOk,
        storageOk: storageOk,
      );
    } on TenantConnectionException {
      rethrow;
    } catch (_) {
      throw const TenantConnectionException(TenantConnectionFailure.unavailable);
    }
  }

  static Future<FirebaseApp> openApprovedWorkspace(String firebaseProjectId) async {
    final String projectId = firebaseProjectId.trim();
    final FirebaseOptions? options = ApprovedTenantFirebase.optionsFor(projectId);
    if (options == null) {
      throw const TenantConnectionException(TenantConnectionFailure.unapproved);
    }
    return ensureApp(tenantId: 'workspace-$projectId', options: options);
  }

  static Future<void> _releaseOtherTenantApps({required String keepName}) async {
    for (final FirebaseApp app in List<FirebaseApp>.from(Firebase.apps)) {
      if (app.name == keepName) continue;
      if (app.name == HackzFirebase.controlPlane.app.name) continue;
      if (!app.name.startsWith(_appPrefix) && !app.name.startsWith('workspace-')) continue;
      try {
        await app.delete();
      } catch (_) {}
    }
  }

  static bool _sameProject(FirebaseOptions a, FirebaseOptions b) {
    return a.projectId == b.projectId && a.apiKey == b.apiKey && a.appId == b.appId;
  }

  static Future<bool> _pingAuth(FirebaseApp app) async {
    try {
      await FirebaseAuth.instanceFor(app: app).authStateChanges().first.timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _pingFirestore(FirebaseApp app) async {
    try {
      await FirebaseFirestore.instanceFor(app: app)
          .collection('hkzOrganizations')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') return false;
      // Permission-denied still means the project is reachable.
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _pingStorage(FirebaseApp app) async {
    return isStorageReachable(app);
  }

  /// True when this workspace has a Storage bucket in its approved Firebase options.
  ///
  /// Do not probe Storage over the network here. Auth/Firestore already prove the
  /// project is reachable; a REST list/metadata call often times out on web
  /// (CORS / `.firebasestorage.app`) even when logo and document uploads work.
  static Future<bool> isStorageReachable(FirebaseApp app) async {
    return storageBucketConfigured(app.options.storageBucket);
  }

  @visibleForTesting
  static bool storageBucketConfigured(String? bucket) {
    final String value = (bucket ?? '').trim();
    if (value.isEmpty) return false;
    final String name = value.startsWith('gs://') ? value.substring(5).trim() : value;
    return name.isNotEmpty;
  }
}
