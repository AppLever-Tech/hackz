import 'package:firebase_core/firebase_core.dart';

import 'approved_tenant_firebase.dart';
import 'tenant_context.dart';
import 'tenant_record.dart';
import 'tenant_registry.dart';

/// Resolves which tenant Firebase project the UI should use.
///
/// `Hackz UI → TenantResolver → TenantContext → HackzFirebase.current`
abstract final class TenantResolver {
  TenantResolver._();

  /// Control Plane (bootstrap) context for the Hackz Firebase project.
  ///
  /// This is not a college tenant. College routing uses
  /// [resolveByOrganisationCode].
  static TenantContext controlPlane(FirebaseOptions options) {
    return TenantContext(
      tenantId: 'control-plane',
      organisationCode: '',
      organisationName: 'Hackz',
      firebaseAppName: defaultFirebaseAppName,
      firebaseOptions: options,
    );
  }

  /// Bootstrap tenant for the current Hackz Firebase project (Control Plane).
  static TenantContext bootstrap(FirebaseOptions options) => controlPlane(options);

  /// Looks up `hkzTenants` by organisation code and returns a [TenantContext]
  /// only for exactly one active tenant on an approved Firebase project.
  ///
  /// Does not bind [HackzFirebase]; callers decide when to switch apps.
  static Future<TenantContext> resolveByOrganisationCode(String rawCode) async {
    final TenantRecord? record = await TenantRegistry.resolveActive(rawCode);
    if (record == null) {
      throw StateError('No active tenant for that organisation code.');
    }
    final FirebaseOptions? options = ApprovedTenantFirebase.optionsFor(record.firebaseProjectId);
    if (options == null) {
      throw StateError('Tenant Firebase project is not approved.');
    }
    final bool sameAsControlPlane = record.firebaseProjectId == ApprovedTenantFirebase.controlPlaneProjectId;
    return TenantContext(
      tenantId: record.tenantId,
      organisationCode: record.organisationCode,
      organisationName: record.organisationName,
      firebaseAppName: sameAsControlPlane ? defaultFirebaseAppName : 'tenant-${record.tenantId}',
      firebaseOptions: options,
    );
  }
}
