import 'package:firebase_core/firebase_core.dart';

import 'tenant_context.dart';

/// Resolves which tenant Firebase project the UI should use.
///
/// Phase 1: always the bootstrap (current) project.
/// Phase 2 extension: Control Plane + Tenant Registry lookup by
/// [organisationCode], then [Firebase.initializeApp] with a named app.
abstract final class TenantResolver {
  TenantResolver._();

  /// Bootstrap tenant for the current single Firebase project.
  ///
  /// Phase 2 replaces this with registry-backed resolution. Callers should
  /// keep going through [HackzFirebase.current] rather than calling this
  /// directly from feature modules.
  static TenantContext bootstrap(FirebaseOptions options) {
    return TenantContext(
      tenantId: options.projectId,
      organisationCode: options.projectId,
      organisationName: 'Hackz',
      firebaseAppName: defaultFirebaseAppName,
      firebaseOptions: options,
    );
  }
}
