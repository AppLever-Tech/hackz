import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/models/score_model.dart';
import '../../evaluations/services/evaluation_results_query_service.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../events/models/event_lifecycle.dart';
import '../../events/models/event_winner_entry.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/organization_model.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';
import '../services/ideathon_service.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

class IdeathonWorkspaceViewModel {
  const IdeathonWorkspaceViewModel({
    required this.ideathon,
    required this.judges,
    required this.coordinators,
    required this.evaluationProgressLabel,
    required this.evaluationProgressPct,
    this.assignmentCount = 0,
    this.completedEvaluationCount = 0,
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
  final int completedEvaluationCount;
  final DateTime? evaluationStartedAt;
  final DateTime? firstAssignedAt;
  final String organisationName;
  final String departmentName;
  final String evaluationTemplateName;
  final EventWinnerEntry? winner;
  final EventWinnerEntry? runnerUp;

  bool get evaluationStarted => evaluationStartedAt != null;

  int get pendingEvaluationCount {
    final int pending = assignmentCount - completedEvaluationCount;
    return pending < 0 ? 0 : pending;
  }

  bool get resultsReady => assignmentCount > 0 && completedEvaluationCount >= assignmentCount;

  EventLifecycleProgress get lifecycleProgress => EventLifecycleProgress(
        hasAssignments: assignmentCount > 0,
        startDateTime: ideathon.startDateTime,
        endDateTime: ideathon.endDateTime,
        evaluationStarted: evaluationStarted,
        completedEvaluationCount: completedEvaluationCount,
        totalEvaluationCount: assignmentCount,
        resultsReviewed: ideathon.resultsReviewedAt != null,
        winnersSelected: ideathon.winnerIdeaId.trim().isNotEmpty,
        completed: ideathon.status == IdeathonStatus.completed ||
            ideathon.status == IdeathonStatus.archived,
      );
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
      HackzFirebase.current.firestore
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
    final String selectedWinner = ideathon.winnerIdeaId.trim();
    final String selectedRunner = ideathon.runnerUpIdeaId.trim();
    if (selectedWinner.isNotEmpty || selectedRunner.isNotEmpty) {
      winner = _winnerEntry(
        ideaId: selectedWinner,
        rank: 1,
        placeLabel: 'Winner',
        results: results,
        snapshots: ideathon.ideas,
        teamByIdea: teamByIdea,
      );
      runnerUp = _winnerEntry(
        ideaId: selectedRunner,
        rank: 2,
        placeLabel: 'Runner-up',
        results: results,
        snapshots: ideathon.ideas,
        teamByIdea: teamByIdea,
      );
    }

    return IdeathonWorkspaceViewModel(
      ideathon: ideathon,
      judges: judges,
      coordinators: coordinators,
      evaluationProgressLabel: label,
      evaluationProgressPct: pct,
      assignmentCount: assignments.length,
      completedEvaluationCount: completed,
      evaluationStartedAt: evaluationStartedAt,
      firstAssignedAt: firstAssignedAt,
      organisationName: (org?.name ?? '').trim(),
      departmentName: (department?.name ?? ideathon.departmentId).trim(),
      evaluationTemplateName: templateName,
      winner: winner,
      runnerUp: runnerUp,
    );
  }

  static EventWinnerEntry? _winnerEntry({
    required String ideaId,
    required int rank,
    required String placeLabel,
    required EvaluationResultsQueryResult results,
    required List<IdeathonIdeaSnapshot> snapshots,
    required Map<String, String> teamByIdea,
  }) {
    final String id = ideaId.trim();
    if (id.isEmpty) return null;
    for (final row in results.rows) {
      if (row.idea.ideaId.trim() != id) continue;
      final String score = row.aggregate.averageScore == null
          ? '—'
          : row.aggregate.averageScore!.toStringAsFixed(2);
      return EventWinnerEntry(
        rank: rank,
        placeLabel: placeLabel,
        ideaId: id,
        ideaTitle: row.idea.ideaTitle.trim().isEmpty ? id : row.idea.ideaTitle.trim(),
        teamId: row.idea.teamId,
        teamName: (teamByIdea[id] ?? '').trim(),
        scoreLabel: score,
        problemId: row.idea.problemId,
        problemTitle: row.problemTitle,
      );
    }
    String title = id;
    String teamName = (teamByIdea[id] ?? '').trim();
    for (final snapshot in snapshots) {
      if (snapshot.ideaId.trim() != id) continue;
      title = snapshot.ideaTitle.trim().isEmpty ? id : snapshot.ideaTitle.trim();
      if (teamName.isEmpty) teamName = snapshot.teamName.trim();
      break;
    }
    return EventWinnerEntry(
      rank: rank,
      placeLabel: placeLabel,
      ideaId: id,
      ideaTitle: title,
      teamId: '',
      teamName: teamName,
      scoreLabel: '—',
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
