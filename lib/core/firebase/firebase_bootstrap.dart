import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'hackz_firebase.dart';
import 'tenant_context.dart';
import 'tenant_resolver.dart';

class FirebaseBootstrap {
  static const String _apiKey = 'AIzaSyAgyqYLei_lpMcWQSaHBfhraDwjZg4t2Rk';
  static const String _messagingSenderId = '439535394674';
  static const String _projectId = 'hackz-a17b6';
  static const String _storageBucket = 'hackz-a17b6.firebasestorage.app';

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    final FirebaseOptions options = _firebaseOptionsForCurrentPlatform;
    await Firebase.initializeApp(options: options);
    final TenantContext controlPlane = TenantResolver.controlPlane(options);
    HackzFirebase.bindControlPlane(controlPlane);
    HackzFirebase.bind(controlPlane);
  }

  static FirebaseOptions get _firebaseOptionsForCurrentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: _apiKey,
        appId: '1:439535394674:web:42af88bf5450b35dd947eb',
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        authDomain: 'hackz-a17b6.firebaseapp.com',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: _apiKey,
          appId: '1:439535394674:android:db0aa1591b7427b6d947eb',
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          storageBucket: _storageBucket,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase is not configured for this platform yet.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase is not configured for fuchsia.',
        );
    }
  }
}
