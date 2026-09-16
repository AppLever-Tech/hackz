import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/hackz_firebase.dart';
import '../../../../core/firebase/hackz_provisioning_client.dart';
import '../../../../core/firebase/tenant_record.dart';
import '../../../../core/firebase/tenant_registry.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../utils/firestore_utils.dart';
import '../models/hkz_org_admin.dart';

class HkzOrgAdminException implements Exception {
  const HkzOrgAdminException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Control Plane CRUD for `hkzOrgAdmins`. SysAdmin UI only.
abstract final class HkzOrgAdminService {
  HkzOrgAdminService._();

  static FirebaseFirestore get _db => HackzFirebase.controlPlane.firestore;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreUtils.hkzOrgAdmins);

  static Future<List<HkzOrgAdmin>> list() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col.orderBy('lastName').get();
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => HkzOrgAdmin.fromMap(doc.id, doc.data())).toList(growable: false);
  }

  static Stream<List<HkzOrgAdmin>> watchAll() {
    return _col.orderBy('lastName').snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => HkzOrgAdmin.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  static Future<HkzOrgAdmin?> fetchById(String id) async {
    final String docId = id.trim();
    if (docId.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col.doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return HkzOrgAdmin.fromMap(doc.id, doc.data()!);
  }

  static Future<HkzOrgAdmin?> fetchByPhone(String phone) async {
    final String normalized = normalizePhoneE164(phone);
    if (normalized.isEmpty) return null;
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('phone', isEqualTo: normalized).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final QueryDocumentSnapshot<Map<String, dynamic>> doc = snap.docs.first;
    return HkzOrgAdmin.fromMap(doc.id, doc.data());
  }

  static Future<List<HkzOrgAdmin>> listActiveForOrganisation(String organisationId) async {
    final String orgId = organisationId.trim();
    if (orgId.isEmpty) return const <HkzOrgAdmin>[];
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('isActive', isEqualTo: true)
        .where('assignedOrganisationIds', arrayContains: orgId)
        .get();
    return snap.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => HkzOrgAdmin.fromMap(doc.id, doc.data())).toList(growable: false);
  }

  static Future<int> countActiveAssignmentsForOrganisation(
    String organisationId, {
    String? excludingOrgAdminId,
  }) async {
    final List<HkzOrgAdmin> admins = await listActiveForOrganisation(organisationId);
    final String exclude = (excludingOrgAdminId ?? '').trim();
    if (exclude.isEmpty) return admins.length;
    return admins.where((HkzOrgAdmin admin) => admin.id != exclude).length;
  }

  static Future<bool> organisationHasActiveOrgAdmin(String organisationId) async {
    return (await countActiveAssignmentsForOrganisation(organisationId)) > 0;
  }

  static Future<HkzOrgAdmin> create({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    List<String> initialOrganisationIds = const <String>[],
    bool isActive = true,
  }) async {
    final String normalizedPhone = normalizePhoneE164(phone);
    if (normalizedPhone.isEmpty) {
      throw const HkzOrgAdminException('A valid mobile number is required.');
    }
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      throw const HkzOrgAdminException('First and last name are required.');
    }
    if (email.trim().isEmpty) {
      throw const HkzOrgAdminException('Email is required.');
    }

    final HkzOrgAdmin? existing = await fetchByPhone(normalizedPhone);
    if (existing != null) {
      throw HkzOrgAdminException('A Hackz org admin already exists for $normalizedPhone.');
    }

    final DateTime now = DateTime.now().toUtc();
    List<String> orgIds = const <String>[];
    for (final String orgId in initialOrganisationIds) {
      orgIds = HkzOrgAdmin.mergeOrganisationAssignments(orgIds, orgId);
    }

    final DocumentReference<Map<String, dynamic>> ref = _col.doc();
    final HkzOrgAdmin record = HkzOrgAdmin(
      id: ref.id,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      phone: normalizedPhone,
      isActive: isActive,
      assignedOrganisationIds: orgIds,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(record.toMap());
    return record;
  }

  static Future<HkzOrgAdmin> setActive({
    required String orgAdminId,
    required bool isActive,
  }) async {
    final HkzOrgAdmin? current = await fetchById(orgAdminId);
    if (current == null) {
      throw const HkzOrgAdminException('That Hackz org admin no longer exists.');
    }
    if (current.isActive == isActive) return current;

    if (!isActive) {
      for (final String orgId in current.assignedOrganisationIds) {
        await _assertCanRemoveLastActiveAssignment(
          organisationId: orgId,
          orgAdminId: current.id,
        );
      }
    }

    final DateTime now = DateTime.now().toUtc();
    await _col.doc(current.id).update(<String, dynamic>{
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(now),
    });
    final HkzOrgAdmin updated = current.copyWith(isActive: isActive, updatedAt: now);
    if (isActive) {
      for (final String orgId in updated.assignedOrganisationIds) {
        await _provisionInTenantIfReady(organisationId: orgId, hackzOrgAdminId: updated.id);
      }
    } else {
      for (final String orgId in updated.assignedOrganisationIds) {
        await _revokeInTenantIfReady(organisationId: orgId, hackzOrgAdminId: updated.id);
      }
    }
    return updated;
  }

  static Future<HkzOrgAdmin> assignOrganisation({
    required String orgAdminId,
    required String organisationId,
    bool syncTenant = true,
  }) async {
    final String orgId = organisationId.trim();
    if (orgId.isEmpty) {
      throw const HkzOrgAdminException('Organisation id is required.');
    }
    final HkzOrgAdmin? current = await fetchById(orgAdminId);
    if (current == null) {
      throw const HkzOrgAdminException('That Hackz org admin no longer exists.');
    }

    await _unassignOrganisationFromOtherAdmins(
      organisationId: orgId,
      exceptOrgAdminId: current.id,
    );

    if (current.isAssignedToOrganisation(orgId)) {
      if (syncTenant && current.isActive) {
        await _provisionInTenantIfReady(organisationId: orgId, hackzOrgAdminId: current.id);
      }
      return current;
    }

    final DateTime now = DateTime.now().toUtc();
    final List<String> next = HkzOrgAdmin.mergeOrganisationAssignments(current.assignedOrganisationIds, orgId);
    await _col.doc(current.id).update(<String, dynamic>{
      'assignedOrganisationIds': next,
      'updatedAt': Timestamp.fromDate(now),
    });
    final HkzOrgAdmin updated = current.copyWith(assignedOrganisationIds: next, updatedAt: now);
    if (syncTenant && updated.isActive) {
      await _provisionInTenantIfReady(organisationId: orgId, hackzOrgAdminId: updated.id);
    }
    return updated;
  }

  static Future<HkzOrgAdmin> removeOrganisationAssignment({
    required String orgAdminId,
    required String organisationId,
    bool syncTenant = true,
  }) async {
    final String orgId = organisationId.trim();
    if (orgId.isEmpty) {
      throw const HkzOrgAdminException('Organisation id is required.');
    }
    final HkzOrgAdmin? current = await fetchById(orgAdminId);
    if (current == null) {
      throw const HkzOrgAdminException('That Hackz org admin no longer exists.');
    }
    if (!current.isAssignedToOrganisation(orgId)) return current;

    await _assertCanRemoveLastActiveAssignment(
      organisationId: orgId,
      orgAdminId: current.id,
    );

    final DateTime now = DateTime.now().toUtc();
    final List<String> next = HkzOrgAdmin.removeOrganisationAssignment(current.assignedOrganisationIds, orgId);
    await _col.doc(current.id).update(<String, dynamic>{
      'assignedOrganisationIds': next,
      'updatedAt': Timestamp.fromDate(now),
    });
    final HkzOrgAdmin updated = current.copyWith(assignedOrganisationIds: next, updatedAt: now);
    if (syncTenant) {
      await _revokeInTenantIfReady(organisationId: orgId, hackzOrgAdminId: updated.id);
    }
    return updated;
  }

  /// One active Hackz org admin per organisation on the Control Plane.
  static Future<void> _unassignOrganisationFromOtherAdmins({
    required String organisationId,
    required String exceptOrgAdminId,
  }) async {
    final String orgId = organisationId.trim();
    final String keepId = exceptOrgAdminId.trim();
    if (orgId.isEmpty || keepId.isEmpty) return;

    final List<HkzOrgAdmin> assigned = await _listAdminsAssignedToOrganisation(orgId);
    final DateTime now = DateTime.now().toUtc();
    for (final HkzOrgAdmin admin in assigned) {
      if (admin.id == keepId || !admin.isAssignedToOrganisation(orgId)) continue;
      final List<String> next = HkzOrgAdmin.removeOrganisationAssignment(admin.assignedOrganisationIds, orgId);
      await _col.doc(admin.id).update(<String, dynamic>{
        'assignedOrganisationIds': next,
        'updatedAt': Timestamp.fromDate(now),
      });
      await _revokeInTenantIfReady(organisationId: orgId, hackzOrgAdminId: admin.id);
    }
  }

  static Future<List<HkzOrgAdmin>> _listAdminsAssignedToOrganisation(String organisationId) async {
    final String orgId = organisationId.trim();
    if (orgId.isEmpty) return const <HkzOrgAdmin>[];
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('assignedOrganisationIds', arrayContains: orgId).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => HkzOrgAdmin.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  static Future<void> _assertCanRemoveLastActiveAssignment({
    required String organisationId,
    required String orgAdminId,
  }) async {
    final String orgId = organisationId.trim();
    if (orgId.isEmpty) return;

    final TenantRecord? tenant = await TenantRegistry.fetchByOrganisationId(orgId);
    if (tenant == null || tenant.status != TenantStatus.active) return;

    final int remaining = await countActiveAssignmentsForOrganisation(orgId, excludingOrgAdminId: orgAdminId);
    if (remaining <= 0) {
      throw const HkzOrgAdminException(
        'Each active organisation must keep at least one active Hackz org admin assignment.',
      );
    }
  }

  static Future<void> _provisionInTenantIfReady({
    required String organisationId,
    required String hackzOrgAdminId,
  }) async {
    final TenantRecord? tenant = await TenantRegistry.fetchByOrganisationId(organisationId);
    if (tenant == null) return;
    if (tenant.firebaseProjectId.trim().isEmpty || !tenant.firebaseValidated) return;
    if (!tenant.provisioningAuthorization.isAuthorized) return;
    try {
      await HackzProvisioningClient.provisionTenantOrgAdmin(
        tenantProjectId: tenant.firebaseProjectId,
        organisationId: organisationId,
        hackzOrgAdminId: hackzOrgAdminId,
      );
    } on HackzProvisioningException catch (e) {
      throw HkzOrgAdminException(e.message);
    }
  }

  /// Removes [organisationId] from every Hackz org admin after the organisation
  /// document is deleted (skips last-admin guard — org no longer exists).
  static Future<void> purgeOrganisationFromAllAdmins(String organisationId) async {
    final String orgId = organisationId.trim();
    if (orgId.isEmpty) return;

    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('assignedOrganisationIds', arrayContains: orgId).get();
    final DateTime now = DateTime.now().toUtc();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final HkzOrgAdmin admin = HkzOrgAdmin.fromMap(doc.id, doc.data());
      if (!admin.isAssignedToOrganisation(orgId)) continue;
      final List<String> next = HkzOrgAdmin.removeOrganisationAssignment(admin.assignedOrganisationIds, orgId);
      await _col.doc(admin.id).update(<String, dynamic>{
        'assignedOrganisationIds': next,
        'updatedAt': Timestamp.fromDate(now),
      });
      await _revokeInTenantIfReady(organisationId: orgId, hackzOrgAdminId: admin.id);
    }
  }

  static Future<void> delete({required String orgAdminId}) async {
    final HkzOrgAdmin? current = await fetchById(orgAdminId);
    if (current == null) {
      throw const HkzOrgAdminException('That Hackz org admin no longer exists.');
    }

    if (current.isActive) {
      for (final String orgId in current.assignedOrganisationIds) {
        await _assertCanRemoveLastActiveAssignment(
          organisationId: orgId,
          orgAdminId: current.id,
        );
      }
    }

    for (final String orgId in current.assignedOrganisationIds) {
      await _revokeInTenantIfReady(organisationId: orgId, hackzOrgAdminId: current.id);
    }
    await _col.doc(current.id).delete();
  }

  static Future<void> _revokeInTenantIfReady({
    required String organisationId,
    required String hackzOrgAdminId,
  }) async {
    final TenantRecord? tenant = await TenantRegistry.fetchByOrganisationId(organisationId);
    if (tenant == null) return;
    if (tenant.firebaseProjectId.trim().isEmpty) return;
    if (!tenant.provisioningAuthorization.isAuthorized) return;
    try {
      await HackzProvisioningClient.revokeTenantOrgAdmin(
        tenantProjectId: tenant.firebaseProjectId,
        organisationId: organisationId,
        hackzOrgAdminId: hackzOrgAdminId,
      );
    } on HackzProvisioningException catch (e) {
      throw HkzOrgAdminException(e.message);
    }
  }
}
