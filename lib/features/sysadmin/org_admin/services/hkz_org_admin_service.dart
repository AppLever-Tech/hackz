import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/firebase/hackz_firebase.dart';
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
    return current.copyWith(isActive: isActive, updatedAt: now);
  }

  static Future<HkzOrgAdmin> assignOrganisation({
    required String orgAdminId,
    required String organisationId,
  }) async {
    final String orgId = organisationId.trim();
    if (orgId.isEmpty) {
      throw const HkzOrgAdminException('Organisation id is required.');
    }
    final HkzOrgAdmin? current = await fetchById(orgAdminId);
    if (current == null) {
      throw const HkzOrgAdminException('That Hackz org admin no longer exists.');
    }
    if (current.isAssignedToOrganisation(orgId)) return current;

    final DateTime now = DateTime.now().toUtc();
    final List<String> next = HkzOrgAdmin.mergeOrganisationAssignments(current.assignedOrganisationIds, orgId);
    await _col.doc(current.id).update(<String, dynamic>{
      'assignedOrganisationIds': next,
      'updatedAt': Timestamp.fromDate(now),
    });
    return current.copyWith(assignedOrganisationIds: next, updatedAt: now);
  }

  static Future<HkzOrgAdmin> removeOrganisationAssignment({
    required String orgAdminId,
    required String organisationId,
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
    return current.copyWith(assignedOrganisationIds: next, updatedAt: now);
  }

  /// Binds an active Hackz org admin to a tenant for Phase 2 provisioning handoff.
  static Future<TenantRecord> bindHackzOrgAdminToTenant({
    required String tenantId,
    required String orgAdminId,
  }) async {
    final HkzOrgAdmin? admin = await fetchById(orgAdminId);
    if (admin == null) {
      throw const HkzOrgAdminException('Select a Hackz org admin.');
    }
    if (!admin.isActive) {
      throw const HkzOrgAdminException('That Hackz org admin is inactive. Choose an active org admin.');
    }

    final TenantRecord tenant = await TenantRegistry.fetchByTenantId(tenantId) ??
        (throw const HkzOrgAdminException('That organisation tenant is no longer in the registry.'));

    final String orgId = tenant.organisationId.trim();
    if (orgId.isEmpty) {
      throw const HkzOrgAdminException('Save the organisation before assigning a Hackz org admin.');
    }

    await assignOrganisation(orgAdminId: admin.id, organisationId: orgId);
    return TenantRegistry.setHackzOrgAdminForTenant(
      tenantId: tenantId,
      hackzOrgAdminId: admin.id,
    );
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
}
