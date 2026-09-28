import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../core/firebase/tenant_firebase.dart';
import '../../../core/firebase/tenant_record.dart';
import '../../organization/models/organization_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/enums/user_status.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import '../models/org_operational_data.dart';

/// SysAdmin organization operations and snapshot loading.
abstract final class OrgManagementService {
  OrgManagementService._();

  static Future<Map<String, OrgOperationalData>> loadOperationalData(
    List<OrganizationModel> organizations, {
    Map<String, String> tenantIdByOrgId = const <String, String>{},
  }) async {
    if (organizations.isEmpty) return <String, OrgOperationalData>{};

    final entries = await Future.wait(
      organizations.map((OrganizationModel org) async {
        final String tenantId = (tenantIdByOrgId[org.id] ?? '').trim();
        try {
          final departmentCount = (await _departmentsFor(org.id, tenantId)).length;
          UserModel? collegeAdmin = await fetchCollegeAdmin(org.id, tenantId: tenantId);
          return MapEntry<String, OrgOperationalData>(
            org.id,
            OrgOperationalData(
              collegeAdmin: collegeAdmin,
              departmentCount: departmentCount,
            ),
          );
        } on FirebaseException catch (e) {
          // Tenant peeks use the org project, not Control Plane Auth. A rules
          // denial must not hide the Control Plane organisation catalog.
          if (e.code == 'permission-denied') {
            return MapEntry<String, OrgOperationalData>(
              org.id,
              const OrgOperationalData(),
            );
          }
          rethrow;
        }
      }),
    );
    return Map<String, OrgOperationalData>.fromEntries(entries);
  }

  static Future<UserModel?> fetchCollegeAdmin(String orgId, {String tenantId = ''}) async {
    final id = orgId.trim();
    if (id.isEmpty) return null;
    Future<UserModel?> fromStore(FirebaseFirestore db) async {
      final QuerySnapshot<Map<String, dynamic>> snap = await db
          .collection(FirestoreUtils.hkzUsers)
          .where('orgId', isEqualTo: id)
          .limit(50)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
        final UserModel user = UserModel.fromMap(doc.data()).copyWith(userId: doc.id);
        if (_isCollegeAdminProfile(user)) return user;
      }
      return null;
    }

    final String tenant = tenantId.trim();
    if (tenant.isNotEmpty) {
      return TenantFirebase.withOrganisationFirestore(tenant, fromStore);
    }
    return fromStore(HackzFirebase.current.firestore);
  }

  static bool _isCollegeAdminProfile(UserModel user) {
    if (user.role.trim() == UserRole.collegeAdmin.code) return true;
    return user.roles.any((String role) => role.trim() == UserRole.collegeAdmin.code);
  }

  /// Prefer live tenant profile; fall back to Control Plane registry snapshot on `hkzTenants`.
  static UserModel? collegeAdminForDisplay({
    required OrganizationModel organization,
    required TenantRecord? tenant,
    UserModel? loadedFromTenant,
  }) {
    if (loadedFromTenant != null) return loadedFromTenant;
    return collegeAdminFromTenantRegistry(organization: organization, tenant: tenant);
  }

  static UserModel? collegeAdminFromTenantRegistry({
    required OrganizationModel organization,
    required TenantRecord? tenant,
  }) {
    final TenantRecord? record = tenant;
    if (record == null || !record.initialAdminConfigured) return null;
    final String first = record.initialCollegeAdminFirstName.trim();
    final String last = record.initialCollegeAdminLastName.trim();
    final String userId = record.initialCollegeAdminUserId.trim();
    if (first.isEmpty && last.isEmpty && userId.isEmpty) return null;
    return UserModel(
      userId: userId,
      phone: record.initialCollegeAdminPhone.trim(),
      firstName: first,
      lastName: last,
      email: record.initialCollegeAdminEmail.trim(),
      role: UserRole.collegeAdmin.code,
      roles: <String>[UserRole.collegeAdmin.code],
      orgType: organization.type,
      orgId: organization.id,
      department: '',
      departmentCode: '',
      status: UserStatus.active,
      createdAt: record.createdAt,
      approvedAt: record.createdAt,
    );
  }

  static Future<List<Map<String, dynamic>>> _departmentsFor(String orgId, String tenantId) {
    if (tenantId.isNotEmpty) {
      return TenantFirebase.withOrganisationFirestore(
        tenantId,
        (FirebaseFirestore db) => FirestoreUtils.getDepartmentsByCollege(orgId, database: db),
      );
    }
    return FirestoreUtils.getDepartmentsByCollege(orgId);
  }

  static String displayOrgCode(String orgId) {
    final id = orgId.trim();
    if (id.length <= 10) return id.toUpperCase();
    return id.substring(0, 10).toUpperCase();
  }
}
