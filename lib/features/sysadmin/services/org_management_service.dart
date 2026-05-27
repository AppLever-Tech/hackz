import '../../../models/enums/organization_type.dart';
import '../../../models/organization_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import '../models/org_operational_data.dart';

/// SysAdmin organization operations and snapshot loading.
abstract final class OrgManagementService {
  OrgManagementService._();

  static Future<Map<String, OrgOperationalData>> loadOperationalData(
    List<OrganizationModel> organizations,
  ) async {
    if (organizations.isEmpty) return <String, OrgOperationalData>{};

    final entries = await Future.wait(
      organizations.map((OrganizationModel org) async {
        final departmentCount = (await FirestoreUtils.getDepartmentsByCollege(org.id)).length;
        UserModel? collegeAdmin;
        if (org.type == OrganizationType.college) {
          collegeAdmin = await fetchCollegeAdmin(org.id);
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

  static Future<UserModel?> fetchCollegeAdmin(String orgId) async {
    final id = orgId.trim();
    if (id.isEmpty) return null;
    final admins = await FirestoreUtils.watchUsersByOrgAndRole(
      orgId: id,
      roleCode: 'CADM',
    ).first;
    if (admins.isEmpty) return null;
    return admins.first;
  }

  static String displayOrgCode(String orgId) {
    final id = orgId.trim();
    if (id.length <= 10) return id.toUpperCase();
    return id.substring(0, 10).toUpperCase();
  }
}
