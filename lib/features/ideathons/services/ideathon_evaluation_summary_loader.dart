import 'package:cloud_firestore/cloud_firestore.dart';

import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/models/score_model.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/enums/organization_commercial_plan.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import '../workspace/ideathon_workspace_loader.dart';

/// Lightweight evaluation metrics for lifecycle UI and primary actions.
abstract final class IdeathonEvaluationSummaryLoader {
  IdeathonEvaluationSummaryLoader._();

  static Future<IdeathonWorkspaceViewModel> load({
    required IdeathonModel ideathon,
    required OrganizationCommercialPlan commercialPlan,
    required String organisationName,
    required List<EvaluationAssignmentModel> assignments,
    required QuerySnapshot<Map<String, dynamic>> scores,
  }) async {
    return buildWorkspace(
      ideathon: ideathon,
      assignments: assignments,
      scores: scores,
      commercialPlan: commercialPlan,
      organisationName: organisationName,
    );
  }

  static IdeathonWorkspaceViewModel buildWorkspace({
    required IdeathonModel ideathon,
    required List<EvaluationAssignmentModel> assignments,
    required QuerySnapshot<Map<String, dynamic>> scores,
    required OrganizationCommercialPlan commercialPlan,
    required String organisationName,
  }) {
    DateTime? firstAssignedAt;
    for (final EvaluationAssignmentModel assignment in assignments) {
      if (firstAssignedAt == null || assignment.assignedAt.isBefore(firstAssignedAt)) {
        firstAssignedAt = assignment.assignedAt;
      }
    }

    final int completed = scores.docs.length;
    DateTime? evaluationStartedAt;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in scores.docs) {
      final ScoreModel score = ScoreModel.fromMap(doc.id, doc.data());
      if (evaluationStartedAt == null || score.createdAt.isBefore(evaluationStartedAt)) {
        evaluationStartedAt = score.createdAt;
      }
    }

    final int totalExpected = assignments.length;
    final double pct = totalExpected == 0 ? 0 : (completed / totalExpected).clamp(0.0, 1.0);
    final String label = totalExpected == 0
        ? 'No judge assignments yet'
        : '$completed / $totalExpected evaluations';

    final DepartmentModel? department = DepartmentModel.byCode(ideathon.departmentId);
    final String templateName =
        EvaluationTemplatesService.findTemplate(ideathon.evaluationTemplateId)?.templateName.trim() ??
            '';

    return IdeathonWorkspaceViewModel(
      ideathon: ideathon,
      judges: const <UserModel>[],
      coordinators: const <UserModel>[],
      evaluationProgressLabel: label,
      evaluationProgressPct: pct,
      assignmentCount: assignments.length,
      completedEvaluationCount: completed,
      evaluationStartedAt: evaluationStartedAt,
      firstAssignedAt: firstAssignedAt,
      organisationName: organisationName,
      departmentName: (department?.name ?? ideathon.departmentId).trim(),
      evaluationTemplateName: templateName,
      commercialPlan: commercialPlan,
    );
  }
}
