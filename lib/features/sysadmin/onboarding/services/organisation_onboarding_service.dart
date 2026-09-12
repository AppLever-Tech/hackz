import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../core/firebase/hackz_provisioning_client.dart';
import '../../../../core/firebase/tenant_firebase.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/firebase/tenant_registry.dart';
import '../../../organization/models/organization_model.dart';
import '../../../../utils/firestore_utils.dart';
import '../../../org_settings/services/org_settings_service.dart';
import '../../models/org_operational_data.dart';
import '../../services/org_management_service.dart';
import '../models/event_entitlement.dart';
import '../models/organisation_onboarding_item.dart';
import 'provisioning_authorization_validator.dart';
import 'tenant_workspace_validator.dart';

class OrganisationOnboardingException implements Exception {
  const OrganisationOnboardingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Control Plane onboarding for colleges. Tenant business data stays in the org project.
abstract final class OrganisationOnboardingService {
  OrganisationOnboardingService._();

  static FirebaseFirestore get _controlPlane => HackzFirebase.controlPlane.firestore;

  static Future<List<OrganisationOnboardingItem>> load() async {
    final List<OrganizationModel> orgs =
        await FirestoreUtils.getOrganizations(database: _controlPlane);
    final List<TenantRecord> tenants = await TenantRegistry.list();

    final Map<String, TenantRecord> tenantByOrgId = <String, TenantRecord>{};
    for (final TenantRecord tenant in tenants) {
      if (tenant.status == TenantStatus.inactive) continue;
      final String orgId = tenant.organisationId.trim();
      if (orgId.isEmpty || tenantByOrgId.containsKey(orgId)) continue;
      tenantByOrgId[orgId] = tenant;
    }

    final Map<String, String> tenantIdByOrgId = <String, String>{
      for (final MapEntry<String, TenantRecord> entry in tenantByOrgId.entries)
        if (entry.value.firebaseProjectId.trim().isNotEmpty) entry.key: entry.value.tenantId,
    };

    final Map<String, OrgOperationalData> operational =
        await OrgManagementService.loadOperationalData(orgs, tenantIdByOrgId: tenantIdByOrgId);

    final List<OrganisationOnboardingItem> items = <OrganisationOnboardingItem>[];
    for (int i = 0; i < orgs.length; i++) {
      final OrganizationModel org = orgs[i];
      TenantRecord? tenant = tenantByOrgId[org.id];
      tenant ??= _uniqueTenantByName(tenants, org.name);
      final OrgOperationalData data = operational[org.id] ?? const OrgOperationalData();
      items.add(
        OrganisationOnboardingItem(
          organization: org,
          tenant: tenant,
          collegeAdmin: data.collegeAdmin,
        ),
      );
    }

    items.sort((OrganisationOnboardingItem a, OrganisationOnboardingItem b) {
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }

  static Future<OrganisationOnboardingItem> saveOrganisation({
    required OrganizationModel draft,
    TenantRecord? existingTenant,
  }) async {
    final OrganizationModel org = draft.copyWith(name: draft.name.trim());
    if (org.name.isEmpty) {
      throw const OrganisationOnboardingException('Organisation name is required.');
    }
    if (org.address.trim().isEmpty || org.website.trim().isEmpty || org.contact.trim().isEmpty) {
      throw const OrganisationOnboardingException('Address, website, and contact are required.');
    }

    final String orgId = await FirestoreUtils.upsertOrganization(org, database: _controlPlane);
    final OrganizationModel saved = org.copyWith(id: orgId);
    final TenantRecord tenant = await TenantRegistry.beginSetup(
      organisationName: saved.name,
      organisationId: orgId,
    );
    if (existingTenant != null && existingTenant.organisationName != saved.name) {
      await TenantRegistry.syncOrganisationName(
        previousName: existingTenant.organisationName,
        nextName: saved.name,
        organisationId: orgId,
      );
    }
    await _mirrorOrganisationToTenant(saved, tenant);
    return OrganisationOnboardingItem(organization: saved, tenant: tenant);
  }

  static Future<TenantRecord> connectWorkspace({
    required String tenantId,
    required String firebaseProjectId,
  }) async {
    final TenantRecord tenant = await TenantRegistry.connectApprovedWorkspace(
      tenantId: tenantId,
      firebaseProjectId: firebaseProjectId,
    );
    await _mirrorOrganisationForTenant(tenant);
    return tenant;
  }

  static Future<List<TenantWorkspaceCheck>> validateWorkspace(
    String firebaseProjectId, {
    TenantWorkspaceCheckProgress? onProgress,
  }) {
    return TenantWorkspaceValidator.validate(firebaseProjectId, onProgress: onProgress);
  }

  static Future<TenantRecord> completeValidation({
    required String tenantId,
    required List<TenantWorkspaceCheck> checks,
  }) async {
    if (!TenantWorkspaceValidator.allPassed(checks)) {
      throw const OrganisationOnboardingException('Resolve the failed checks before continuing.');
    }
    return TenantRegistry.markFirebaseValidated(tenantId);
  }

  static Future<TenantRecord> markAuthorizationPending(String tenantId) {
    return TenantRegistry.setProvisioningAuthorization(
      tenantId,
      ProvisioningAuthorizationStatus.pending,
    );
  }

  static Future<List<TenantWorkspaceCheck>> validateProvisioningAuthorization(
    String firebaseProjectId,
  ) {
    return ProvisioningAuthorizationValidator.validate(firebaseProjectId);
  }

  static Future<TenantRecord> completeProvisioningAuthorization({
    required String tenantId,
    required List<TenantWorkspaceCheck> checks,
    required ProvisioningAuthorizationStatus previous,
  }) {
    if (ProvisioningAuthorizationValidator.allPassed(checks)) {
      return TenantRegistry.setProvisioningAuthorization(
        tenantId,
        ProvisioningAuthorizationStatus.verified,
      );
    }
    final ProvisioningAuthorizationStatus next = previous.isAuthorized
        ? ProvisioningAuthorizationStatus.revoked
        : ProvisioningAuthorizationStatus.pending;
    return TenantRegistry.setProvisioningAuthorization(tenantId, next);
  }

  /// Re-runs college IAM validation. Does not change tenant users or business data.
  static Future<TenantRecord> revalidateProvisioningAuthorization(TenantRecord tenant) async {
    if (tenant.firebaseProjectId.trim().isEmpty) {
      throw const OrganisationOnboardingException(
        'Connect a workspace before validating authorization.',
      );
    }
    final List<TenantWorkspaceCheck> checks = await validateProvisioningAuthorization(
      tenant.firebaseProjectId,
    );
    final TenantRecord updated = await completeProvisioningAuthorization(
      tenantId: tenant.tenantId,
      checks: checks,
      previous: tenant.provisioningAuthorization,
    );
    if (!ProvisioningAuthorizationValidator.allPassed(checks)) {
      throw OrganisationOnboardingException(updated.provisioningAuthorization.lifecycleMessage);
    }
    return updated;
  }

  static Future<TenantRecord> markAdministratorReady(String tenantId) {
    return TenantRegistry.markInitialAdminConfigured(tenantId);
  }

  static Future<HackzProvisioningResult> provisionInitialCollegeAdmin({
    required TenantRecord tenant,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    if (!tenant.provisioningAuthorization.isAuthorized) {
      throw OrganisationOnboardingException(
        tenant.provisioningAuthorization.isRevoked
            ? tenant.provisioningAuthorization.lifecycleMessage
            : 'Validate college authorization before creating the College Admin.',
      );
    }
    if (!tenant.firebaseValidated || tenant.firebaseProjectId.trim().isEmpty) {
      throw const OrganisationOnboardingException(
        'Connect and check the workspace before creating the College Admin.',
      );
    }
    try {
      return await HackzProvisioningClient.provisionTenantAdmin(
        tenantProjectId: tenant.firebaseProjectId,
        organisationId: tenant.organisationId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );
    } on HackzProvisioningException catch (e) {
      throw OrganisationOnboardingException(e.message);
    }
  }

  static Future<TenantRecord> activate(String tenantId) async {
    final TenantRecord current = await TenantRegistry.fetchByTenantId(tenantId) ??
        (throw const OrganisationOnboardingException('That organisation is no longer in the registry.'));
    if (!current.provisioningAuthorization.isAuthorized) {
      throw OrganisationOnboardingException(
        current.provisioningAuthorization.isRevoked
            ? current.provisioningAuthorization.lifecycleMessage
            : 'The college must authorize Hackz provisioning before activation.',
      );
    }
    if (!current.initialAdminConfigured) {
      throw const OrganisationOnboardingException(
        'Create the initial College Admin before activation.',
      );
    }
    final TenantRecord tenant = await TenantRegistry.activate(tenantId);
    await _mirrorOrganisationForTenant(tenant);
    return tenant;
  }

  static String get defaultWorkspaceId => ApprovedTenantFirebase.controlPlaneProjectId;

  /// Writes organisation status and commercial plan on Control Plane `hkzOrganizations` only.
  static Future<void> updateCommercialAccess(OrganizationModel org) async {
    if (org.id.trim().isEmpty) return;
    await FirestoreUtils.upsertOrganization(org, database: _controlPlane);
  }

  static Future<List<EventEntitlement>> listEventEntitlements(String orgId) async {
    final String id = orgId.trim();
    if (id.isEmpty) return const <EventEntitlement>[];
    final QuerySnapshot<Map<String, dynamic>> snap = await _controlPlane
        .collection(FirestoreUtils.hkzEventEntitlements)
        .where('orgId', isEqualTo: id)
        .get();
    final List<EventEntitlement> items = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => EventEntitlement.fromMap(doc.id, doc.data()))
        .toList();
    items.sort((EventEntitlement a, EventEntitlement b) {
      final DateTime aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final int byDate = bAt.compareTo(aAt);
      if (byDate != 0) return byDate;
      return a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase());
    });
    return items;
  }

  /// Writes the organisation catalog row on the Control Plane and, when a
  /// tenant workspace is connected, copies the same document to that project.
  static Future<void> syncOrganisationDocument(OrganizationModel org) async {
    if (org.id.trim().isEmpty) return;
    await FirestoreUtils.upsertOrganization(org, database: _controlPlane);
    final List<TenantRecord> tenants = await TenantRegistry.list();
    for (final TenantRecord tenant in tenants) {
      if (tenant.status == TenantStatus.inactive) continue;
      if (tenant.organisationId.trim() != org.id.trim()) continue;
      await _mirrorOrganisationToTenant(org, tenant);
      return;
    }
  }

  static Future<void> _mirrorOrganisationForTenant(TenantRecord tenant) async {
    final String orgId = tenant.organisationId.trim();
    if (orgId.isEmpty || tenant.firebaseProjectId.trim().isEmpty) return;
    final OrganizationModel? org =
        await FirestoreUtils.fetchOrganization(orgId, database: _controlPlane);
    if (org == null) return;
    await _mirrorOrganisationToTenant(org, tenant);
  }

  static Future<void> _mirrorOrganisationToTenant(
    OrganizationModel org,
    TenantRecord tenant,
  ) async {
    final String tenantId = tenant.tenantId.trim();
    if (tenantId.isEmpty || tenant.firebaseProjectId.trim().isEmpty) return;
    if (org.id.trim().isEmpty) return;
    try {
      await TenantFirebase.withOrganisationFirestore(tenantId, (FirebaseFirestore db) async {
        await db.collection(FirestoreUtils.hkzOrganizations).doc(org.id).set(
              org.toCatalogMap(),
              SetOptions(merge: true),
            );
        // Tenant operational settings — never written to Control Plane hkzOrganizations.
        await OrgSettingsService.seedFor(org.id, firestore: db);
      });
    } catch (_) {
      // Tenant project may not be reachable yet during early setup.
    }
  }

  static TenantRecord? _uniqueTenantByName(List<TenantRecord> tenants, String name) {
    final String target = name.trim();
    if (target.isEmpty) return null;
    final List<TenantRecord> matches = tenants
        .where((TenantRecord tenant) => tenant.status != TenantStatus.inactive)
        .where((TenantRecord tenant) => tenant.organisationName.trim() == target)
        .where((TenantRecord tenant) => tenant.organisationId.trim().isEmpty)
        .toList(growable: false);
    if (matches.length != 1) return null;
    return matches.first;
  }
}
