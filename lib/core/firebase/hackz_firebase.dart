import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'tenant_context.dart';

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

  /// True while a SysAdmin is signed in on Control Plane Auth.
  static bool get isPlatformAdminSession => _platformAdminSession;

  /// Auth that owns the signed-in Hackz session (OTP / AuthGate).
  ///
  /// College users: [current]. Platform SysAdmin: Control Plane, even when
  /// [current] is rebound to a tenant for organisation data.
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
  FirebaseStorage get storage => FirebaseStorage.instanceFor(app: app);

  /// Binds the Control Plane to the bootstrap (Hackz) Firebase app.
  static void bindControlPlane(TenantContext context, {FirebaseApp? app}) {
    _controlPlane = HackzFirebase._(context, app ?? Firebase.app(context.firebaseAppName));
    generation.value++;
    tenantGeneration.value++;
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
  }
}
