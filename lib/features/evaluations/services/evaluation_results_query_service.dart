import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import '../../organization/models/department_model.dart';
import '../../problems/models/problem_model.dart';
import '../../user/models/user_model.dart';
import '../../user/services/role_visibility_helpers.dart';
import 'evaluation_ranking_service.dart';
import 'evaluation_settings_service.dart';
import 'evaluation_aggregation_sync_service.dart';

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
  });

  final UserModel viewer;
  final String search;
  final Set<String> departmentFilters;
  final Set<String> problemFilters;
  final Set<String> categoryFilters;
  final Set<IdeaStatus> statusFilters;
  final int limit;
}

class EvaluationResultsMetrics {
  const EvaluationResultsMetrics({
    required this.totalEvaluated,
    required this.ideathonAssigned,
    required this.rejected,
  });

  static const EvaluationResultsMetrics empty = EvaluationResultsMetrics(
    totalEvaluated: 0,
    ideathonAssigned: 0,
    rejected: 0,
  );

  final int totalEvaluated;
  final int ideathonAssigned;
  final int rejected;
}

class EvaluationResultsQueryResult {
  const EvaluationResultsQueryResult({
    required this.rows,
    required this.metrics,
    required this.problemsById,
    required this.categories,
    required this.departments,
  });

  final List<EvaluationResultsRow> rows;
  final EvaluationResultsMetrics metrics;
  final Map<String, String> problemsById;
  final List<String> categories;
  final List<String> departments;
}

/// Loads ranked evaluation outcomes for department-admin review.
abstract final class EvaluationResultsQueryService {
  EvaluationResultsQueryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Set<IdeaStatus> _reviewStatuses = <IdeaStatus>{
    IdeaStatus.evaluated,
    IdeaStatus.ideathonAssigned,
    IdeaStatus.rejected,
  };

  static Future<EvaluationResultsQueryResult> fetch(EvaluationResultsQueryParams params) async {
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
        .where((IdeaModel idea) => _reviewStatuses.contains(idea.status) || idea.hasEvaluationAggregate)
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

  static EvaluationResultsMetrics _computeMetrics(List<IdeaModel> ideas) {
    if (ideas.isEmpty) return EvaluationResultsMetrics.empty;
    return EvaluationResultsMetrics(
      totalEvaluated: ideas
          .where(
            (IdeaModel i) =>
                i.status == IdeaStatus.evaluated ||
                i.status == IdeaStatus.ideathonAssigned ||
                i.hasEvaluationAggregate,
          )
          .length,
      ideathonAssigned: ideas.where((IdeaModel i) => i.status == IdeaStatus.ideathonAssigned).length,
      rejected: ideas.where((IdeaModel i) => i.status == IdeaStatus.rejected).length,
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
