import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'tenant_context.dart';
import 'tenant_session_hooks.dart';

/// Single Firebase access point for Hackz.
///
/// Flow: `Hackz UI → TenantResolver → TenantContext → HackzFirebase.current`
///
/// Feature modules must use [HackzFirebase.current] instead of
/// `FirebaseAuth.instance` / `FirebaseFirestore.instance` / `FirebaseStorage.instance`.
///
/// [controlPlane] always talks to the Hackz Control Plane (bootstrap project)
/// for tenant registry / routing. [current] is the active tenant app after
/// [bind] and may be re-bound without changing feature services.
class HackzFirebase {
  HackzFirebase._(this.context, this.app);

  final TenantContext context;
  final FirebaseApp app;

  static HackzFirebase? _current;
  static HackzFirebase? _controlPlane;
  static bool _platformAdminSession = false;

  /// Increments when the signed-in Auth app changes (college connect / logout).
  static final ValueNotifier<int> generation = ValueNotifier<int>(0);

  /// Increments when [current] is rebound for data access, including SysAdmin
  /// organisation switching that must not remount [AuthGate].
  static final ValueNotifier<int> tenantGeneration = ValueNotifier<int>(0);

  static HackzFirebase get current {
    final HackzFirebase? bound = _current;
    if (bound == null) {
      throw StateError(
        'HackzFirebase is not bound. Call HackzFirebase.bind after tenant validation.',
      );
    }
    return bound;
  }

  /// Control Plane Auth/Firestore/Storage (tenant registry). Independent of [current].
  static HackzFirebase get controlPlane {
    final HackzFirebase? bound = _controlPlane;
    if (bound == null) {
      throw StateError(
        'HackzFirebase control plane is not bound. Call HackzFirebase.bindControlPlane after Firebase initialization.',
      );
    }
    return bound;
  }

  static bool get isBound => _current != null;

  /// True when [current] is a resolved college tenant, not the Control Plane.
  static bool get isTenantBound {
    final HackzFirebase? bound = _current;
    if (bound == null) return false;
    return bound.context.organisationCode.isNotEmpty;
  }

  /// True when [current] is an organisation workspace (setup or active).
  ///
  /// Hosted colleges share the Control Plane Firebase project; they still
  /// count because [TenantContext.tenantId] is the organisation tenant.
  static bool get isOrganisationWorkspace {
    final HackzFirebase? bound = _current;
    if (bound == null) return false;
    return bound.context.isOrganisationWorkspace;
  }

  /// Organisation-specific files must use tenant Storage, never Control Plane.
  static void assertOrganisationStorage() {
    if (!isOrganisationWorkspace) {
      throw StateError(
        'Organisation files must use the active tenant Firebase Storage.',
      );
    }
  }

  /// True while a SysAdmin is signed in on Control Plane Auth.
  static bool get isPlatformAdminSession => _platformAdminSession;

  /// Auth that owns the signed-in Hackz session (OTP / AuthGate).
  ///
  /// Organisation users after tenant resolution: [current.auth]
  /// (`HackzFirebase.current.auth`). Platform SysAdmin: Control Plane Auth,
  /// even when [current] is rebound to a tenant for organisation data.
  static FirebaseAuth get sessionAuth {
    if (_platformAdminSession) return controlPlane.auth;
    return current.auth;
  }

  static void beginPlatformAdminSession() {
    _platformAdminSession = true;
  }

  static void endPlatformAdminSession() {
    _platformAdminSession = false;
  }

  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);
  FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(app: app);

  /// Storage for this bound app. Do not cache [Reference]s across tenant rebinds;
  /// resolve through [HackzFirebase.current.storage] after each bind.
  FirebaseStorage get storage => FirebaseStorage.instanceFor(app: app);

  /// Binds the Control Plane to the bootstrap (Hackz) Firebase app.
  static void bindControlPlane(TenantContext context, {FirebaseApp? app}) {
    _controlPlane = HackzFirebase._(context, app ?? Firebase.app(context.firebaseAppName));
    generation.value++;
    tenantGeneration.value++;
    TenantSessionHooks.notifyRebound();
  }

  /// Binds the active tenant app. Does not replace [controlPlane].
  static void bind(
    TenantContext context, {
    FirebaseApp? app,
    bool notifySession = true,
  }) {
    _current = HackzFirebase._(context, app ?? Firebase.app(context.firebaseAppName));
    tenantGeneration.value++;
    if (notifySession) generation.value++;
    TenantSessionHooks.notifyRebound();
  }

  /// Runs [action] against [app] as [current] without notifying session or
  /// tenant generation. Used by the platform console to read/write one
  /// organisation's tenant project without switching the SysAdmin session.
  /// Restores the previous [current] even if [action] throws.
  static Future<T> runWithCurrent<T>(
    TenantContext context,
    FirebaseApp app,
    Future<T> Function() action,
  ) async {
    final HackzFirebase? previous = _current;
    _current = HackzFirebase._(context, app);
    try {
      return await action();
    } finally {
      _current = previous;
    }
  }
}
