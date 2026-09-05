import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../core/firebase/tenant_firebase.dart';
import '../../organization/models/enums/organization_type.dart';
import '../../organization/models/organization_model.dart';
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
        final departmentCount = (await _departmentsFor(org.id, tenantId)).length;
        UserModel? collegeAdmin;
        if (org.type == OrganizationType.college) {
          collegeAdmin = await fetchCollegeAdmin(org.id, tenantId: tenantId);
        }
        return MapEntry<String, OrgOperationalData>(
          org.id,
          OrgOperationalData(
            collegeAdmin: collegeAdmin,
            departmentCount: departmentCount,
          ),
        );
      }),
    );
    return Map<String, OrgOperationalData>.fromEntries(entries);
  }

  static Future<UserModel?> fetchCollegeAdmin(String orgId, {String tenantId = ''}) async {
    final id = orgId.trim();
    if (id.isEmpty) return null;
    Future<UserModel?> fromStore(FirebaseFirestore db) async {
      final admins = await FirestoreUtils.watchUsersByOrgAndRole(
        orgId: id,
        roleCode: 'CADM',
        database: db,
      ).first;
      if (admins.isEmpty) return null;
      return admins.first;
    }

    final String tenant = tenantId.trim();
    if (tenant.isNotEmpty) {
      return TenantFirebase.withOrganisationFirestore(tenant, fromStore);
    }
    return fromStore(HackzFirebase.current.firestore);
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
