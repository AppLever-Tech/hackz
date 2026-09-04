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
/// Phase 1 binds the current (default) project; Phase 2 can re-bind a named
/// tenant app without changing feature services.
class HackzFirebase {
  HackzFirebase._(this.context, this.app);

  final TenantContext context;
  final FirebaseApp app;

  static HackzFirebase? _current;

  static HackzFirebase get current {
    final HackzFirebase? bound = _current;
    if (bound == null) {
      throw StateError(
        'HackzFirebase is not bound. Call HackzFirebase.bind after Firebase initialization.',
      );
    }
    return bound;
  }

  static bool get isBound => _current != null;

  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);
  FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(app: app);
  FirebaseStorage get storage => FirebaseStorage.instanceFor(app: app);

  /// Binds [context] to an initialized [FirebaseApp] (default app in Phase 1).
  ///
  /// Phase 2: `Firebase.initializeApp(name: context.firebaseAppName, options:
  /// context.firebaseOptions)` then [bind] that named app.
  static void bind(TenantContext context, {FirebaseApp? app}) {
    _current = HackzFirebase._(context, app ?? Firebase.app(context.firebaseAppName));
  }
}
