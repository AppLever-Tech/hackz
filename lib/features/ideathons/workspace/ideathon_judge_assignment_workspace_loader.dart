import '../../../utils/firestore_utils.dart';
import '../../organization/models/organization_model.dart';
import '../services/ideathon_judge_assignment_service.dart';

class IdeathonJudgeAssignmentWorkspaceViewModel {
  const IdeathonJudgeAssignmentWorkspaceViewModel({
    required this.assignments,
    required this.organisationName,
  });

  final IdeathonJudgeAssignmentViewModel assignments;
  final String organisationName;
}

abstract final class IdeathonJudgeAssignmentWorkspaceLoader {
  IdeathonJudgeAssignmentWorkspaceLoader._();

  static Future<IdeathonJudgeAssignmentWorkspaceViewModel> load(String ideathonId) async {
    final String id = ideathonId.trim();
    final IdeathonJudgeAssignmentViewModel assignments =
        await IdeathonJudgeAssignmentService.load(id);

    final String orgId = assignments.ideathon.orgId.trim();
    final OrganizationModel? org =
        orgId.isEmpty ? null : await FirestoreUtils.fetchOrganization(orgId);

    return IdeathonJudgeAssignmentWorkspaceViewModel(
      assignments: assignments,
      organisationName: (org?.name ?? '').trim(),
    );
  }
}
