import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../assignments/services/evaluation_assignment_service.dart';

/// Determines whether a user should see judge-style assigned evaluation flows.
class EvaluatorAccessService {
  EvaluatorAccessService._();

  static Future<bool> shouldShowAssignedEvaluations(UserModel user) async {
    return user.hasRoleCode(UserRole.judge.code) || user.role.trim() == UserRole.judge.code;
  }

  static Future<bool> hasActiveAssignments({
    required String orgId,
    required String evaluatorId,
  }) async {
    final Set<String> ideaIds = await EvaluationAssignmentService.assignedIdeaIdsForJudge(
      orgId: orgId,
      judgeId: evaluatorId,
    );
    return ideaIds.isNotEmpty;
  }
}
