import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/models/score_model.dart';
import '../../idea/models/idea_model.dart';
import '../../ideathons/services/ideathon_service.dart';
import '../../organization/models/department_model.dart';
import '../../problems/models/problem_model.dart';
import '../../user/models/user_model.dart';
import '../../user/services/role_visibility_helpers.dart';
import 'evaluation_aggregation_service.dart';
import 'evaluation_aggregation_sync_service.dart';
import 'evaluation_ranking_service.dart';
import 'evaluation_settings_service.dart';

/// Filters for the Evaluation Results workspace.
class EvaluationResultsQueryParams {
  const EvaluationResultsQueryParams({
    required this.viewer,
    this.search = '',
    this.departmentFilters = const <String>{},
    this.problemFilters = const <String>{},
    this.categoryFilters = const <String>{},
    this.statusFilters = const <IdeaStatus>{},
    this.limit = 500,
    this.ideathonId = '',
  });

  final UserModel viewer;
  final String search;
  final Set<String> departmentFilters;
  final Set<String> problemFilters;
  final Set<String> categoryFilters;
  final Set<IdeaStatus> statusFilters;
  final int limit;

  /// When set, results are strictly scoped to this Ideathon event.
  final String ideathonId;
}

class EvaluationResultsMetrics {
  const EvaluationResultsMetrics({
    required this.totalEvaluated,
    required this.pendingReview,
  });

  static const EvaluationResultsMetrics empty = EvaluationResultsMetrics(
    totalEvaluated: 0,
    pendingReview: 0,
  );

  final int totalEvaluated;
  final int pendingReview;
}

class EvaluationResultsQueryResult {
  const EvaluationResultsQueryResult({
    required this.rows,
    required this.metrics,
    required this.problemsById,
    required this.categories,
    required this.departments,
    this.ideathonId = '',
    this.ideathonName = '',
    this.evaluationTemplateId = '',
  });

  final List<EvaluationResultsRow> rows;
  final EvaluationResultsMetrics metrics;
  final Map<String, String> problemsById;
  final List<String> categories;
  final List<String> departments;
  final String ideathonId;
  final String ideathonName;
  final String evaluationTemplateId;

  bool get isIdeathonScoped => ideathonId.trim().isNotEmpty;
}

/// Loads ranked evaluation outcomes for department-admin review.
abstract final class EvaluationResultsQueryService {
  EvaluationResultsQueryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<EvaluationResultsQueryResult> fetch(EvaluationResultsQueryParams params) async {
    final String eventId = params.ideathonId.trim();
    if (eventId.isNotEmpty) {
      return _fetchIdeathonResults(params, eventId);
    }
    return _fetchPipelineResults(params);
  }

  static Future<EvaluationResultsQueryResult> _fetchPipelineResults(
    EvaluationResultsQueryParams params,
  ) async {
    final String orgId = params.viewer.orgId.trim();
    if (orgId.isEmpty) {
      return const EvaluationResultsQueryResult(
        rows: <EvaluationResultsRow>[],
        metrics: EvaluationResultsMetrics.empty,
        problemsById: <String, String>{},
        categories: <String>[],
        departments: <String>[],
      );
    }

    // Use the session org-settings snapshot (loaded at login). Do not force a
    // mid-session refresh — College Admin edits elsewhere stay offline until
    // this user logs out and back in.
    await EvaluationSettingsService.ensureLoaded(orgId: orgId);
    await EvaluationAggregationSyncService.reconcileOrg(orgId: orgId);

    final String deptCode = DepartmentModel.resolveCode(params.viewer.departmentCode);

    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: orgId).limit(params.limit).get(),
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: orgId).get(),
    ]);

    final QuerySnapshot<Map<String, dynamic>> ideasSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> problemsSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;

    final Map<String, ProblemModel> problems = <String, ProblemModel>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in problemsSnap.docs)
        doc.id: ProblemModel.fromMap(doc.id, doc.data()),
    };

    final Map<String, String> problemsById = <String, String>{
      for (final MapEntry<String, ProblemModel> e in problems.entries)
        e.key: e.value.title.trim().isEmpty ? e.key : e.value.title.trim(),
    };

    final Set<String> categories = <String>{};
    final Set<String> departments = <String>{};

    List<IdeaModel> ideas = ideasSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => IdeaModel.fromMap(doc.id, doc.data()))
        .where((IdeaModel idea) => idea.status == IdeaStatus.submitted || idea.hasEvaluationAggregate)
        .toList(growable: false);

    if (deptCode.isNotEmpty) {
      ideas = ideas
          .where(
            (IdeaModel idea) => RoleVisibilityHelpers.ideaMatchesDepartmentScope(
              idea,
              IdeaDepartmentScope.teamDepartment,
              deptCode,
            ),
          )
          .toList(growable: false);
    }

    for (final IdeaModel idea in ideas) {
      final ProblemModel? problem = problems[idea.problemId];
      final String category = (problem?.category ?? '').trim();
      if (category.isNotEmpty) categories.add(category);
      final String dep = idea.problemDepartmentCode.trim();
      if (dep.isNotEmpty) departments.add(dep);
    }

    final EvaluationResultsMetrics metrics = _computeMetrics(ideas);

    ideas = _applyFilters(
      ideas: ideas,
      problems: problems,
      params: params,
    );

    final List<EvaluationResultsRow> ranked = EvaluationRankingService.buildRankedRows(
      ideas: ideas,
      problems: problems,
    );

    return EvaluationResultsQueryResult(
      rows: ranked,
      metrics: metrics,
      problemsById: problemsById,
      categories: categories.toList()..sort(),
      departments: departments.toList()..sort(),
    );
  }

  /// Ideathon-scoped results from event scores/assignments only (never other events).
  static Future<EvaluationResultsQueryResult> _fetchIdeathonResults(
    EvaluationResultsQueryParams params,
    String eventId,
  ) async {
    final ideathon = await IdeathonService.fetchById(eventId);
    if (ideathon == null) {
      throw StateError('Ideathon not found.');
    }
    final String orgId = ideathon.orgId.trim();
    await EvaluationSettingsService.ensureLoaded(orgId: orgId);

    final List<String> ideaIds = ideathon.ideas
        .map((snapshot) => snapshot.ideaId.trim())
        .where((String id) => id.isNotEmpty)
        .toList(growable: false);

    final List<dynamic> parallel = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: orgId).get(),
      _db
          .collection(FirestoreUtils.hkzScores)
          .where('orgId', isEqualTo: orgId)
          .where('ideathonId', isEqualTo: eventId)
          .get(),
      EvaluationAssignmentService.listByIdeathon(ideathonId: eventId),
      _loadIdeasByIds(ideaIds),
    ]);

    final QuerySnapshot<Map<String, dynamic>> problemsSnap =
        parallel[0] as QuerySnapshot<Map<String, dynamic>>;
    final QuerySnapshot<Map<String, dynamic>> scoresSnap =
        parallel[1] as QuerySnapshot<Map<String, dynamic>>;
    final List<EvaluationAssignmentModel> assignments =
        parallel[2] as List<EvaluationAssignmentModel>;
    final Map<String, IdeaModel> ideasById = parallel[3] as Map<String, IdeaModel>;

    final Map<String, ProblemModel> problems = <String, ProblemModel>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in problemsSnap.docs)
        doc.id: ProblemModel.fromMap(doc.id, doc.data()),
    };
    final Map<String, String> problemsById = <String, String>{
      for (final MapEntry<String, ProblemModel> e in problems.entries)
        e.key: e.value.title.trim().isEmpty ? e.key : e.value.title.trim(),
    };

    final Map<String, List<ScoreModel>> scoresByIdea = <String, List<ScoreModel>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in scoresSnap.docs) {
      final ScoreModel score = ScoreModel.fromMap(doc.id, doc.data());
      if (score.ideathonId.trim() != eventId) continue;
      final String ideaId = score.ideaId.trim();
      if (ideaId.isEmpty || !ideasById.containsKey(ideaId)) continue;
      scoresByIdea.putIfAbsent(ideaId, () => <ScoreModel>[]).add(score);
    }

    final Map<String, Set<String>> assignedJudgesByIdea = <String, Set<String>>{};
    for (final EvaluationAssignmentModel a in assignments) {
      if (!a.isActive) continue;
      final String ideaId = a.ideaId.trim();
      if (ideaId.isEmpty || !ideasById.containsKey(ideaId)) continue;
      final String judgeId = a.judgeId.trim();
      if (judgeId.isEmpty) continue;
      assignedJudgesByIdea.putIfAbsent(ideaId, () => <String>{}).add(judgeId);
    }

    final Set<String> categories = <String>{};
    final Set<String> departments = <String>{};
    final List<IdeaModel> ideas = <IdeaModel>[];
    final Map<String, IdeaEvaluationAggregate> aggregates = <String, IdeaEvaluationAggregate>{};
    final Set<String> completeIdeaIds = <String>{};
    final Map<String, int> assignedCountByIdea = <String, int>{};

    for (final String ideaId in ideaIds) {
      final IdeaModel? idea = ideasById[ideaId];
      if (idea == null) continue;
      ideas.add(idea);
      final ProblemModel? problem = problems[idea.problemId];
      final String category = (problem?.category ?? '').trim();
      if (category.isNotEmpty) categories.add(category);
      final String dep = idea.problemDepartmentCode.trim();
      if (dep.isNotEmpty) departments.add(dep);

      final List<ScoreModel> scores = scoresByIdea[ideaId] ?? const <ScoreModel>[];
      aggregates[ideaId] = EvaluationAggregationService.computeFromScores(scores);

      final Set<String> assigned = assignedJudgesByIdea[ideaId] ?? const <String>{};
      assignedCountByIdea[ideaId] = assigned.length;
      final Set<String> scoredJudges = scores
          .map((ScoreModel s) => s.judgeId.trim())
          .where((String id) => id.isNotEmpty)
          .toSet();
      // Final only when every assigned judge has submitted for this Ideathon.
      final bool complete = assigned.isNotEmpty && assigned.every(scoredJudges.contains);
      if (complete) completeIdeaIds.add(ideaId);
    }

    final List<IdeaModel> filtered = _applyFilters(
      ideas: ideas,
      problems: problems,
      params: params,
    );

    final List<EvaluationResultsRow> rows = EvaluationRankingService.buildRowsFromAggregates(
      ideas: filtered,
      problems: problems,
      aggregatesByIdeaId: aggregates,
      completeIdeaIds: completeIdeaIds,
      assignedJudgesByIdeaId: assignedCountByIdea,
    );

    final int evaluated = filtered.where((IdeaModel i) => completeIdeaIds.contains(i.ideaId)).length;
    final EvaluationResultsMetrics metrics = EvaluationResultsMetrics(
      totalEvaluated: evaluated,
      pendingReview: filtered.length - evaluated,
    );

    return EvaluationResultsQueryResult(
      rows: rows,
      metrics: metrics,
      problemsById: problemsById,
      categories: categories.toList()..sort(),
      departments: departments.toList()..sort(),
      ideathonId: eventId,
      ideathonName: ideathon.name,
      evaluationTemplateId: ideathon.evaluationTemplateId,
    );
  }

  static Future<Map<String, IdeaModel>> _loadIdeasByIds(List<String> ideaIds) async {
    final Map<String, IdeaModel> byId = <String, IdeaModel>{};
    const int chunkSize = 10;
    for (int i = 0; i < ideaIds.length; i += chunkSize) {
      final List<String> chunk = ideaIds.sublist(
        i,
        i + chunkSize > ideaIds.length ? ideaIds.length : i + chunkSize,
      );
      final List<DocumentSnapshot<Map<String, dynamic>>> docs = await Future.wait(
        chunk.map((String id) => _db.collection(FirestoreUtils.hkzIdeas).doc(id).get()),
      );
      for (final DocumentSnapshot<Map<String, dynamic>> doc in docs) {
        if (!doc.exists || doc.data() == null) continue;
        byId[doc.id] = IdeaModel.fromMap(doc.id, doc.data()!);
      }
    }
    return byId;
  }

  static EvaluationResultsMetrics _computeMetrics(List<IdeaModel> ideas) {
    if (ideas.isEmpty) return EvaluationResultsMetrics.empty;
    final int totalEvaluated = ideas.where((IdeaModel i) => i.hasEvaluationAggregate).length;
    return EvaluationResultsMetrics(
      totalEvaluated: totalEvaluated,
      pendingReview: ideas.where((IdeaModel i) => i.status == IdeaStatus.submitted && !i.hasEvaluationAggregate).length,
    );
  }

  static List<IdeaModel> _applyFilters({
    required List<IdeaModel> ideas,
    required Map<String, ProblemModel> problems,
    required EvaluationResultsQueryParams params,
  }) {
    final String q = params.search.trim().toLowerCase();
    Iterable<IdeaModel> filtered = ideas;

    if (params.statusFilters.isNotEmpty) {
      filtered = filtered.where((IdeaModel i) => params.statusFilters.contains(i.status));
    }
    if (params.departmentFilters.isNotEmpty) {
      filtered = filtered.where((IdeaModel i) => params.departmentFilters.contains(i.problemDepartmentCode.trim()));
    }
    if (params.problemFilters.isNotEmpty) {
      filtered = filtered.where((IdeaModel i) => params.problemFilters.contains(i.problemId.trim()));
    }
    if (params.categoryFilters.isNotEmpty) {
      filtered = filtered.where((IdeaModel i) {
        final ProblemModel? p = problems[i.problemId];
        return params.categoryFilters.contains((p?.category ?? '').trim());
      });
    }
    if (q.isNotEmpty) {
      filtered = filtered.where((IdeaModel i) {
        final String ideaTitle = i.ideaTitle.trim().toLowerCase();
        final ProblemModel? p = problems[i.problemId];
        final String problemTitle = (p?.title ?? i.problemTitle).trim().toLowerCase();
        return ideaTitle.contains(q) || problemTitle.contains(q);
      });
    }

    return filtered.toList(growable: false);
  }
}
