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
    this.organisationId = '',
  });

  /// [tenantId] for the Hackz Control Plane. Not an organisation workspace.
  static const String controlPlaneTenantId = 'control-plane';

  /// Internal immutable tenant identifier.
  final String tenantId;

  /// True when this context is an organisation Firebase workspace (setup or
  /// active), including a hosted workspace that shares the Control Plane project.
  bool get isOrganisationWorkspace =>
      tenantId.isNotEmpty && tenantId != controlPlaneTenantId;

  /// User-facing routing key (`HKZ-XXXXXX`). Never require [tenantId] in URLs.
  final String organisationCode;

  final String organisationName;

  /// Tenant `hkzOrganizations` document id. Empty on the Control Plane.
  final String organisationId;

  /// [FirebaseApp.name] for this tenant. `[DEFAULT]` for the bootstrap project.
  final String firebaseAppName;

  /// Project/configuration used to initialize or attach the tenant Firebase app.
  final FirebaseOptions firebaseOptions;
}
