import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/models/score_model.dart';
import '../../evaluations/services/evaluation_results_query_service.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../events/models/event_lifecycle.dart';
import '../../events/models/event_place_config.dart';
import '../../events/models/event_winner_entry.dart';
import '../../organization/models/department_model.dart';
import '../../organization/models/enums/organization_commercial_plan.dart';
import '../../organization/models/organization_model.dart';
import '../../organization/services/commercial_access.dart';
import '../../organization/services/organisation_access.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';
import '../services/event_details_evaluation_bundle.dart';
import '../services/event_details_tab_cache.dart';
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
    this.thirdPlace,
    this.commercialPlan = OrganizationCommercialPlan.perIdea,
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
  final EventWinnerEntry? thirdPlace;
  final OrganizationCommercialPlan commercialPlan;

  bool get requiresIdeaPayment => CommercialAccess.requiresIdeaPayment(commercialPlan);

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

  IdeathonWorkspaceViewModel copyWith({
    IdeathonModel? ideathon,
    List<UserModel>? judges,
    List<UserModel>? coordinators,
    String? evaluationProgressLabel,
    double? evaluationProgressPct,
    int? assignmentCount,
    int? completedEvaluationCount,
    DateTime? evaluationStartedAt,
    DateTime? firstAssignedAt,
    String? organisationName,
    String? departmentName,
    String? evaluationTemplateName,
    EventWinnerEntry? winner,
    EventWinnerEntry? runnerUp,
    EventWinnerEntry? thirdPlace,
    OrganizationCommercialPlan? commercialPlan,
  }) {
    return IdeathonWorkspaceViewModel(
      ideathon: ideathon ?? this.ideathon,
      judges: judges ?? this.judges,
      coordinators: coordinators ?? this.coordinators,
      evaluationProgressLabel: evaluationProgressLabel ?? this.evaluationProgressLabel,
      evaluationProgressPct: evaluationProgressPct ?? this.evaluationProgressPct,
      assignmentCount: assignmentCount ?? this.assignmentCount,
      completedEvaluationCount: completedEvaluationCount ?? this.completedEvaluationCount,
      evaluationStartedAt: evaluationStartedAt ?? this.evaluationStartedAt,
      firstAssignedAt: firstAssignedAt ?? this.firstAssignedAt,
      organisationName: organisationName ?? this.organisationName,
      departmentName: departmentName ?? this.departmentName,
      evaluationTemplateName: evaluationTemplateName ?? this.evaluationTemplateName,
      winner: winner ?? this.winner,
      runnerUp: runnerUp ?? this.runnerUp,
      thirdPlace: thirdPlace ?? this.thirdPlace,
      commercialPlan: commercialPlan ?? this.commercialPlan,
    );
  }
}

abstract final class IdeathonWorkspaceLoader {
  IdeathonWorkspaceLoader._();

  static Future<IdeathonWorkspaceViewModel> load(String ideathonId) async {
    final IdeathonModel? loaded = await IdeathonService.fetchById(ideathonId);
    if (loaded == null) throw StateError('Ideathon not found');
    IdeathonModel ideathon = loaded;

    try {
      await IdeathonService.ensurePerEventEntitlement(ideathon);
      ideathon = await IdeathonService.fetchById(ideathonId) ?? ideathon;
    } catch (error) {
      debugPrint('Event entitlement registration retry failed for ${ideathon.ideathonId}: $error');
    }

    bool rosterChanged = false;
    if (await IdeathonService.promoteEligibleSubmissionsWithoutIdeaPayment(ideathon.ideathonId)) {
      ideathon = await IdeathonService.fetchById(ideathonId) ?? ideathon;
      rosterChanged = true;
    }

    if (!rosterChanged) {
      final EventDetailsEvaluationBundle? cached =
          EventDetailsTabCache.forEvent(ideathonId).peek<EventDetailsEvaluationBundle>(
        EventDetailsTabKeys.evaluationBundle,
      );
      if (cached != null) {
        return _fromCachedEvaluationBundle(ideathon: ideathon, cached: cached);
      }
    }

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
      ideathon.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : OrganisationAccess.fetch(ideathon.orgId),
    ]);

    final List<UserModel> judges = parallel[0] as List<UserModel>;
    final List<UserModel> coordinators = parallel[1] as List<UserModel>;
    final List<EvaluationAssignmentModel> assignments =
        parallel[2] as List<EvaluationAssignmentModel>;
    final QuerySnapshot<Map<String, dynamic>> scores =
        parallel[3] as QuerySnapshot<Map<String, dynamic>>;
    final OrganizationModel? org = parallel[4] as OrganizationModel?;
    final EvaluationResultsQueryResult results = parallel[5] as EvaluationResultsQueryResult;
    final OrganizationModel? controlPlaneOrg = parallel[6] as OrganizationModel?;
    final OrganizationCommercialPlan commercialPlan = CommercialAccess.planOf(controlPlaneOrg);

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
    EventWinnerEntry? thirdPlace;
    final String selectedWinner = ideathon.winnerIdeaId.trim();
    final String selectedRunner = ideathon.runnerUpIdeaId.trim();
    final String selectedThird = ideathon.thirdPlaceIdeaId.trim();
    if (selectedWinner.isNotEmpty || selectedRunner.isNotEmpty || selectedThird.isNotEmpty) {
      winner = _winnerEntry(
        ideaId: selectedWinner,
        rank: EventPlaceRank.first.rank,
        placeLabel: EventPlacePresentation.cardTitle(EventPlaceRank.first),
        results: results,
        snapshots: ideathon.ideas,
        teamByIdea: teamByIdea,
      );
      runnerUp = _winnerEntry(
        ideaId: selectedRunner,
        rank: EventPlaceRank.second.rank,
        placeLabel: EventPlacePresentation.cardTitle(EventPlaceRank.second),
        results: results,
        snapshots: ideathon.ideas,
        teamByIdea: teamByIdea,
      );
      thirdPlace = _winnerEntry(
        ideaId: selectedThird,
        rank: EventPlaceRank.third.rank,
        placeLabel: EventPlacePresentation.cardTitle(EventPlaceRank.third),
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
      organisationName: _organisationName(org: org, orgId: ideathon.orgId),
      departmentName: (department?.name ?? ideathon.departmentId).trim(),
      evaluationTemplateName: templateName,
      winner: winner,
      runnerUp: runnerUp,
      thirdPlace: thirdPlace,
      commercialPlan: commercialPlan,
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

  static String _organisationName({required OrganizationModel? org, required String orgId}) {
    final String id = orgId.trim();
    final String fromDoc = (org?.name ?? '').trim();
    if (fromDoc.isNotEmpty && fromDoc != id) return fromDoc;

    if (HackzFirebase.isOrganisationWorkspace) {
      final String boundName = HackzFirebase.current.context.organisationName.trim();
      final String boundId = HackzFirebase.current.context.organisationId.trim();
      if (boundName.isNotEmpty && boundName != id && boundName != boundId) {
        return boundName;
      }
    }

    return '';
  }

  static Future<IdeathonWorkspaceViewModel> _fromCachedEvaluationBundle({
    required IdeathonModel ideathon,
    required EventDetailsEvaluationBundle cached,
  }) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: ideathon.orgId);

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      _fetchUsers(ideathon.judgeIds),
      _fetchUsers(ideathon.coordinatorIds),
      ideathon.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : FirestoreUtils.fetchOrganization(ideathon.orgId),
      ideathon.orgId.trim().isEmpty
          ? Future<OrganizationModel?>.value(null)
          : OrganisationAccess.fetch(ideathon.orgId),
    ]);

    final List<UserModel> judges = parallel[0] as List<UserModel>;
    final List<UserModel> coordinators = parallel[1] as List<UserModel>;
    final OrganizationModel? org = parallel[2] as OrganizationModel?;
    final OrganizationModel? controlPlaneOrg = parallel[3] as OrganizationModel?;
    final OrganizationCommercialPlan commercialPlan = CommercialAccess.planOf(controlPlaneOrg);

    final Map<String, String> teamByIdea = <String, String>{
      for (final IdeathonIdeaSnapshot snapshot in ideathon.ideas) snapshot.ideaId: snapshot.teamName,
    };
    final EvaluationResultsQueryResult results = cached.results;
    EventWinnerEntry? winner;
    EventWinnerEntry? runnerUp;
    EventWinnerEntry? thirdPlace;
    final String selectedWinner = ideathon.winnerIdeaId.trim();
    final String selectedRunner = ideathon.runnerUpIdeaId.trim();
    final String selectedThird = ideathon.thirdPlaceIdeaId.trim();
    if (selectedWinner.isNotEmpty || selectedRunner.isNotEmpty || selectedThird.isNotEmpty) {
      winner = _winnerEntry(
        ideaId: selectedWinner,
        rank: EventPlaceRank.first.rank,
        placeLabel: EventPlacePresentation.cardTitle(EventPlaceRank.first),
        results: results,
        snapshots: ideathon.ideas,
        teamByIdea: teamByIdea,
      );
      runnerUp = _winnerEntry(
        ideaId: selectedRunner,
        rank: EventPlaceRank.second.rank,
        placeLabel: EventPlacePresentation.cardTitle(EventPlaceRank.second),
        results: results,
        snapshots: ideathon.ideas,
        teamByIdea: teamByIdea,
      );
      thirdPlace = _winnerEntry(
        ideaId: selectedThird,
        rank: EventPlaceRank.third.rank,
        placeLabel: EventPlacePresentation.cardTitle(EventPlaceRank.third),
        results: results,
        snapshots: ideathon.ideas,
        teamByIdea: teamByIdea,
      );
    }

    return cached.workspace.copyWith(
      ideathon: ideathon,
      judges: judges,
      coordinators: coordinators,
      organisationName: _organisationName(org: org, orgId: ideathon.orgId),
      commercialPlan: commercialPlan,
      winner: winner,
      runnerUp: runnerUp,
      thirdPlace: thirdPlace,
    );
  }

  static Future<List<UserModel>> _fetchUsers(List<String> ids) async {
    final List<String> unique = <String>{
      for (final String raw in ids) raw.trim(),
    }.where((String id) => id.isNotEmpty).toList(growable: false);
    if (unique.isEmpty) return const <UserModel>[];

    final List<UserModel?> loaded = await Future.wait<UserModel?>(
      unique.map((String id) => FirestoreUtils.fetchUser(id)),
    );
    final List<UserModel> users = loaded.whereType<UserModel>().toList(growable: true);
    users.sort((UserModel a, UserModel b) => userDisplayName(a).compareTo(userDisplayName(b)));
    return users;
  }
}
