import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'tenant_context.dart';

/// Single Firebase access point for Hackz.
///
/// Flow: `Hackz UI → TenantResolver → TenantContext → HackzFirebase.current`
///
/// Feature modules must use [HackzFirebase.current] instead of
/// `FirebaseAuth.instance` / `FirebaseFirestore.instance` / `FirebaseStorage.instance`.
///
/// [controlPlane] always talks to the Hackz Control Plane (bootstrap project)
/// for tenant registry / routing. [current] is the active tenant app and may
/// be re-bound later without changing feature services.
class HackzFirebase {
  HackzFirebase._(this.context, this.app);

  final TenantContext context;
  final FirebaseApp app;

  static HackzFirebase? _current;
  static HackzFirebase? _controlPlane;

  static HackzFirebase get current {
    final HackzFirebase? bound = _current;
    if (bound == null) {
      throw StateError(
        'HackzFirebase is not bound. Call HackzFirebase.bind after Firebase initialization.',
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

  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);
  FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(app: app);
  FirebaseStorage get storage => FirebaseStorage.instanceFor(app: app);

  /// Binds the Control Plane to the bootstrap (Hackz) Firebase app.
  static void bindControlPlane(TenantContext context, {FirebaseApp? app}) {
    _controlPlane = HackzFirebase._(context, app ?? Firebase.app(context.firebaseAppName));
  }

  /// Binds the active tenant app. Does not replace [controlPlane].
  ///
  /// Later routing: `Firebase.initializeApp(name: context.firebaseAppName,
  /// options: context.firebaseOptions)` then [bind] that named app.
  static void bind(TenantContext context, {FirebaseApp? app}) {
    _current = HackzFirebase._(context, app ?? Firebase.app(context.firebaseAppName));
    _controlPlane ??= _current;
  }
}
