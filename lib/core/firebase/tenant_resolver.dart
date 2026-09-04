import 'package:firebase_core/firebase_core.dart';

import 'approved_tenant_firebase.dart';
import 'organisation_code.dart';
import 'tenant_connection_exception.dart';
import 'tenant_context.dart';
import 'tenant_firebase.dart';
import 'tenant_record.dart';
import 'tenant_registry.dart';

/// Resolves which tenant Firebase project the UI should use.
///
/// `Organisation Code → Control Plane registry → TenantContext → Tenant Firebase`
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
  /// Does not bind [HackzFirebase]. Call [TenantFirebase.connect] to initialize
  /// and bind the tenant app.
  static Future<TenantContext> resolveByOrganisationCode(String rawCode) async {
    if (OrganisationCode.tryParse(rawCode) == null) {
      throw const TenantConnectionException(TenantConnectionFailure.invalidCode);
    }

    await ApprovedTenantFirebase.refresh();

    final TenantRecord? record;
    try {
      record = await TenantRegistry.lookupByOrganisationCode(rawCode);
    } on StateError {
      throw const TenantConnectionException(TenantConnectionFailure.conflict);
    }

    if (record == null) {
      throw const TenantConnectionException(TenantConnectionFailure.notFound);
    }
    if (record.status != TenantStatus.active) {
      throw const TenantConnectionException(TenantConnectionFailure.inactive);
    }

    final FirebaseOptions? options = ApprovedTenantFirebase.optionsFor(record.firebaseProjectId);
    if (options == null) {
      throw const TenantConnectionException(TenantConnectionFailure.unapproved);
    }

    return TenantContext(
      tenantId: record.tenantId,
      organisationCode: record.organisationCode,
      organisationName: record.organisationName,
      firebaseAppName: TenantFirebase.appNameFor(
        tenantId: record.tenantId,
        projectId: record.firebaseProjectId,
        controlPlaneProjectId: ApprovedTenantFirebase.controlPlaneProjectId,
      ),
      firebaseOptions: options,
    );
  }
}
