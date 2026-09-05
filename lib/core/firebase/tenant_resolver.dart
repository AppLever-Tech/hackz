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
      tenantId: TenantContext.controlPlaneTenantId,
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

    return _validatedContext(record);
  }

  /// Resolves an active, approved tenant by Control Plane registry id.
  ///
  /// Used by SysAdmin organisation access. Does not treat the organisation
  /// code as an authorization secret.
  static Future<TenantContext> resolveByTenantId(String tenantId) async {
    final String id = tenantId.trim();
    if (id.isEmpty) {
      throw const TenantConnectionException(TenantConnectionFailure.notFound);
    }

    await ApprovedTenantFirebase.refresh();
    final TenantRecord? record = await TenantRegistry.fetchByTenantId(id);
    return _validatedContext(record);
  }

  /// Platform-admin workspace access for setup or active tenants.
  ///
  /// Used to read/write organisation Firestore/Storage during onboarding
  /// before the tenant is activated. Login routing still uses [resolveByTenantId].
  static Future<TenantContext> workspaceByTenantId(String tenantId) async {
    final String id = tenantId.trim();
    if (id.isEmpty) {
      throw const TenantConnectionException(TenantConnectionFailure.notFound);
    }

    await ApprovedTenantFirebase.refresh();
    final TenantRecord? record = await TenantRegistry.fetchByTenantId(id);
    if (record == null) {
      throw const TenantConnectionException(TenantConnectionFailure.notFound);
    }
    if (record.status == TenantStatus.inactive) {
      throw const TenantConnectionException(TenantConnectionFailure.inactive);
    }
    if (record.firebaseProjectId.trim().isEmpty) {
      throw const TenantConnectionException(TenantConnectionFailure.unapproved);
    }

    final FirebaseOptions? options = ApprovedTenantFirebase.optionsFor(record.firebaseProjectId);
    if (options == null) {
      throw const TenantConnectionException(TenantConnectionFailure.unapproved);
    }
    return _contextFrom(record, options);
  }

  static Future<TenantContext> _validatedContext(TenantRecord? record) async {
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
    return _contextFrom(record, options);
  }

  static TenantContext _contextFrom(TenantRecord record, FirebaseOptions options) {
    return TenantContext(
      tenantId: record.tenantId,
      organisationCode: record.organisationCode,
      organisationName: record.organisationName,
      organisationId: record.organisationId,
      firebaseAppName: TenantFirebase.appNameFor(
        tenantId: record.tenantId,
        projectId: record.firebaseProjectId,
        controlPlaneProjectId: ApprovedTenantFirebase.controlPlaneProjectId,
      ),
      firebaseOptions: options,
    );
  }
}
