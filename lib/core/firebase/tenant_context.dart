import 'package:firebase_core/firebase_core.dart';

/// Infrastructure identity of the active organisation.
///
/// Holds routing and Firebase project references only. Do not put business
/// fields (problems, ideas, teams, users) here — tenant isolation is the
/// Firebase project boundary, not a `tenantId` on domain models.
class TenantContext {
  const TenantContext({
    required this.tenantId,
    required this.organisationCode,
    required this.organisationName,
    required this.firebaseAppName,
    required this.firebaseOptions,
  });

  /// Internal immutable tenant identifier.
  final String tenantId;

  /// User-facing routing code (Phase 2 organisation-code login).
  final String organisationCode;

  final String organisationName;

  /// [FirebaseApp.name] for this tenant. `[DEFAULT]` for the bootstrap project.
  final String firebaseAppName;

  /// Project/configuration used to initialize or attach the tenant Firebase app.
  final FirebaseOptions firebaseOptions;
}
