import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/models/score_model.dart';
import '../../evaluations/services/evaluation_results_query_service.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../events/models/event_winner_entry.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/organization_model.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import '../services/ideathon_service.dart';

class IdeathonWorkspaceViewModel {
  const IdeathonWorkspaceViewModel({
    required this.ideathon,
    required this.judges,
    required this.coordinators,
    required this.evaluationProgressLabel,
    required this.evaluationProgressPct,
    this.assignmentCount = 0,
    this.evaluationStartedAt,
    this.firstAssignedAt,
    this.organisationName = '',
    this.departmentName = '',
    this.evaluationTemplateName = '',
    this.winner,
    this.runnerUp,
  });

  final IdeathonModel ideathon;
  final List<UserModel> judges;
  final List<UserModel> coordinators;
  final String evaluationProgressLabel;
  final double evaluationProgressPct;
  final int assignmentCount;
  final DateTime? evaluationStartedAt;
  final DateTime? firstAssignedAt;
  final String organisationName;
  final String departmentName;
  final String evaluationTemplateName;
  final EventWinnerEntry? winner;
  final EventWinnerEntry? runnerUp;

  bool get evaluationStarted => evaluationStartedAt != null;
}

abstract final class IdeathonWorkspaceLoader {
  IdeathonWorkspaceLoader._();

  static Future<IdeathonWorkspaceViewModel> load(String ideathonId) async {
    final IdeathonModel? ideathon = await IdeathonService.fetchById(ideathonId);
    if (ideathon == null) throw StateError('Ideathon not found');

    await OrgSettingsService.instance.ensureLoaded(orgId: ideathon.orgId);

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchUsers(ideathon.judgeIds),
      _fetchUsers(ideathon.coordinatorIds),
      EvaluationAssignmentService.listByIdeathon(ideathonId: ideathon.ideathonId),
      FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzScores)
          .where('orgId', isEqualTo: ideathon.orgId)
          .where('ideathonId', isEqualTo: ideathon.ideathonId)
          .get(),
      ideathon.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : FirestoreUtils.fetchOrganization(ideathon.orgId),
      EvaluationResultsQueryService.fetch(
        EvaluationResultsQueryParams(ideathonId: ideathon.ideathonId),
      ),
    ]);

    final List<UserModel> judges = parallel[0] as List<UserModel>;
    final List<UserModel> coordinators = parallel[1] as List<UserModel>;
    final List<EvaluationAssignmentModel> assignments =
        parallel[2] as List<EvaluationAssignmentModel>;
    final QuerySnapshot<Map<String, dynamic>> scores =
        parallel[3] as QuerySnapshot<Map<String, dynamic>>;
    final OrganizationModel? org = parallel[4] as OrganizationModel?;
    final EvaluationResultsQueryResult results = parallel[5] as EvaluationResultsQueryResult;

    DateTime? firstAssignedAt;
    for (final assignment in assignments) {
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

    final Map<String, String> teamByIdea = <String, String>{
      for (final snapshot in ideathon.ideas) snapshot.ideaId: snapshot.teamName,
    };
    EventWinnerEntry? winner;
    EventWinnerEntry? runnerUp;
    for (final row in results.rows) {
      if (row.rank != 1 && row.rank != 2) continue;
      if (!row.evaluationComplete) continue;
      final String score = row.aggregate.averageScore == null
          ? '—'
          : row.aggregate.averageScore!.toStringAsFixed(2);
      final EventWinnerEntry entry = EventWinnerEntry(
        rank: row.rank,
        placeLabel: row.rank == 1 ? 'Winner' : 'Runner-up',
        ideaId: row.idea.ideaId,
        ideaTitle: row.idea.ideaTitle.trim().isEmpty ? row.idea.ideaId : row.idea.ideaTitle.trim(),
        teamId: row.idea.teamId,
        teamName: (teamByIdea[row.idea.ideaId] ?? '').trim(),
        scoreLabel: score,
      );
      if (row.rank == 1) winner = entry;
      if (row.rank == 2) runnerUp = entry;
    }

    return IdeathonWorkspaceViewModel(
      ideathon: ideathon,
      judges: judges,
      coordinators: coordinators,
      evaluationProgressLabel: label,
      evaluationProgressPct: pct,
      assignmentCount: assignments.length,
      evaluationStartedAt: evaluationStartedAt,
      firstAssignedAt: firstAssignedAt,
      organisationName: (org?.name ?? '').trim(),
      departmentName: (department?.name ?? ideathon.departmentId).trim(),
      evaluationTemplateName: templateName,
      winner: winner,
      runnerUp: runnerUp,
    );
  }

  static Future<List<UserModel>> _fetchUsers(List<String> ids) async {
    final List<UserModel> users = <UserModel>[];
    for (final String raw in ids) {
      final String id = raw.trim();
      if (id.isEmpty) continue;
      final UserModel? user = await FirestoreUtils.fetchUser(id);
      if (user != null) users.add(user);
    }
    users.sort((UserModel a, UserModel b) => userDisplayName(a).compareTo(userDisplayName(b)));
    return users;
  }
}
