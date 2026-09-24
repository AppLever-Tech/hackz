import '../../../../features/organization/models/organization_model.dart';
import '../../../../utils/firestore_utils.dart';
import 'college_dashboard_analytics.dart';

/// Single fetch for college admin overview (avoids duplicate idea/user queries).
abstract final class CollegeDashboardLoader {
  CollegeDashboardLoader._();

  static Future<CollegeDashboardSnapshot> load(String orgId) async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.getDepartmentsByCollege(orgId),
      FirestoreUtils.getProblemStatementsByCollege(orgId),
      FirestoreUtils.getCollegeIdeaDocuments(orgId),
      FirestoreUtils.fetchOrganization(orgId, preferServer: true),
    ]);

    return CollegeDashboardSnapshot(
      departments: results[0] as List<Map<String, dynamic>>,
      problems: results[1] as List<Map<String, dynamic>>,
      ideas: results[2] as List<Map<String, dynamic>>,
      org: results[3] as OrganizationModel?,
    );
  }
}
