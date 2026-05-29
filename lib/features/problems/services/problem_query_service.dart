import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/department_model.dart';
import '../../../utils/firestore_utils.dart';
import '../models/problem_list_config.dart';
import '../models/problem_model.dart';

class ProblemQueryParams {
  const ProblemQueryParams({
    required this.config,
    required this.search,
    required this.sortType,
    required this.statusFilter,
    required this.departmentFilters,
    required this.tagFilters,
    required this.hasAttachments,
    this.limit = 300,
  });

  final ProblemListConfig config;
  final String search;
  final ProblemSortType sortType;
  final bool? statusFilter;
  final Set<String> departmentFilters;
  final Set<String> tagFilters;
  final bool? hasAttachments;
  final int limit;
}

class ProblemDashboardMetrics {
  const ProblemDashboardMetrics({
    required this.total,
    required this.myDepartment,
    required this.withIdeas,
    required this.withoutIdeas,
  });

  static const ProblemDashboardMetrics empty = ProblemDashboardMetrics(
    total: 0,
    myDepartment: 0,
    withIdeas: 0,
    withoutIdeas: 0,
  );

  final int total;
  final int myDepartment;
  final int withIdeas;
  final int withoutIdeas;
}

class ProblemListQueryResult {
  const ProblemListQueryResult({
    required this.items,
    required this.metrics,
    required this.ideaCountByProblemId,
  });

  final List<ProblemModel> items;
  final ProblemDashboardMetrics metrics;
  final Map<String, int> ideaCountByProblemId;
}

class ProblemQueryService {
  ProblemQueryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<ProblemListQueryResult> fetchProblems(ProblemQueryParams params) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _db.collection(FirestoreUtils.hkzProblems).where('orgId', isEqualTo: params.config.orgId).limit(params.limit).get(),
      _db.collection(FirestoreUtils.hkzIdeas).where('orgId', isEqualTo: params.config.orgId).get(),
    ]);

    final problemsSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final ideasSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;

    final allProblems = problemsSnap.docs
        .map((doc) => ProblemModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    final ideaCountByProblemId = <String, int>{};
    for (final doc in ideasSnap.docs) {
      final data = doc.data();
      final problemId = ((data['problemId'] as String?) ?? '').trim();
      if (problemId.isEmpty) continue;
      ideaCountByProblemId[problemId] = (ideaCountByProblemId[problemId] ?? 0) + 1;
    }

    final scoped = _applyDepartmentRestriction(allProblems, params);
    final metrics = _computeMetrics(
      scoped,
      ideaCountByProblemId,
      params.config.departmentCode,
    );

    var items = List<ProblemModel>.from(scoped);
    items = _applyFilters(items, params);
    items = await _applyAttachmentFilter(
      items: items,
      orgId: params.config.orgId,
      hasAttachments: params.hasAttachments,
    );
    items = _applySort(items, params.sortType, ideaCountByProblemId);

    return ProblemListQueryResult(
      items: items,
      metrics: metrics,
      ideaCountByProblemId: ideaCountByProblemId,
    );
  }

  static List<ProblemModel> _applyDepartmentRestriction(List<ProblemModel> items, ProblemQueryParams params) {
    if (!params.config.restrictToDepartment) return items;
    final restrictedDepartmentCode = DepartmentModel.resolveCode(params.config.departmentCode);
    if (restrictedDepartmentCode.isEmpty) return items;
    return items
        .where(
          (problem) => problem.departmentCode.trim().toUpperCase() == restrictedDepartmentCode,
        )
        .toList(growable: false);
  }

  static ProblemDashboardMetrics _computeMetrics(
    List<ProblemModel> problems,
    Map<String, int> ideaCountByProblemId,
    String viewerDepartmentCode,
  ) {
    if (problems.isEmpty) return ProblemDashboardMetrics.empty;
    final String dept = DepartmentModel.resolveCode(viewerDepartmentCode);
    final int myDepartment = dept.isEmpty
        ? 0
        : problems.where((ProblemModel p) => p.departmentCode.trim().toUpperCase() == dept).length;
    final int withIdeas =
        problems.where((ProblemModel p) => (ideaCountByProblemId[p.problemId] ?? 0) > 0).length;
    return ProblemDashboardMetrics(
      total: problems.length,
      myDepartment: myDepartment,
      withIdeas: withIdeas,
      withoutIdeas: problems.length - withIdeas,
    );
  }

  static List<ProblemModel> _applyFilters(List<ProblemModel> items, ProblemQueryParams params) {
    final search = params.search.trim().toLowerCase();
    final restrictedDepartmentCode = params.config.departmentCode.trim().toUpperCase();
    final selectedDepartmentCodes = params.departmentFilters
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    return items.where((problem) {
      if (params.config.restrictToDepartment && restrictedDepartmentCode.isNotEmpty) {
        if (problem.departmentCode.trim().toUpperCase() != restrictedDepartmentCode) {
          return false;
        }
      }
      if (params.statusFilter != null && problem.isActive != params.statusFilter) {
        return false;
      }
      if (selectedDepartmentCodes.isNotEmpty &&
          !selectedDepartmentCodes.contains(problem.departmentCode.trim().toUpperCase())) {
        return false;
      }
      if (params.tagFilters.isNotEmpty) {
        final tags = problem.tags.map((e) => e.toLowerCase()).toSet();
        final hasAll = params.tagFilters.every((filterTag) => tags.contains(filterTag.toLowerCase()));
        if (!hasAll) return false;
      }
      if (search.isNotEmpty) {
        final inTitle = problem.title.toLowerCase().contains(search);
        final inNumber = problem.problemNumber.toLowerCase().contains(search);
        final inTags = problem.tags.any((t) => t.toLowerCase().contains(search));
        if (!inTitle && !inNumber && !inTags) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  static Future<List<ProblemModel>> _applyAttachmentFilter({
    required List<ProblemModel> items,
    required String orgId,
    required bool? hasAttachments,
  }) async {
    if (hasAttachments == null) return items;
    final snap = await _db
        .collection(FirestoreUtils.hkzAttachments)
        .where('orgId', isEqualTo: orgId)
        .where('entityType', isEqualTo: 'problem')
        .where('isActive', isEqualTo: true)
        .get();
    final attachedProblemIds = snap.docs
        .map((d) => ((d.data()['entityId'] as String?) ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    return items.where((p) {
      final hasAny = attachedProblemIds.contains(p.problemId);
      return hasAny == hasAttachments;
    }).toList(growable: false);
  }

  static List<ProblemModel> _applySort(
    List<ProblemModel> items,
    ProblemSortType sortType,
    Map<String, int> ideaCountByProblemId,
  ) {
    final sorted = List<ProblemModel>.from(items);
    switch (sortType) {
      case ProblemSortType.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ProblemSortType.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ProblemSortType.titleAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case ProblemSortType.department:
        sorted.sort((a, b) =>
            a.departmentCode.toLowerCase().compareTo(b.departmentCode.toLowerCase()));
      case ProblemSortType.category:
        sorted.sort((a, b) =>
            a.category.toLowerCase().compareTo(b.category.toLowerCase()));
      case ProblemSortType.psNumber:
        // Natural-ish sort: pad each PS # to a fixed length so "PS-2" precedes
        // "PS-10". Fall back to a plain compare when the value is empty.
        sorted.sort((a, b) {
          final String pa = a.problemNumber.trim().toLowerCase();
          final String pb = b.problemNumber.trim().toLowerCase();
          return _naturalCompare(pa, pb);
        });
      case ProblemSortType.ideasCount:
        // Highest submission count first; ties broken by newest createdAt so
        // active problems float above stale ones.
        sorted.sort((a, b) {
          final int ca = ideaCountByProblemId[a.problemId] ?? 0;
          final int cb = ideaCountByProblemId[b.problemId] ?? 0;
          if (ca != cb) return cb.compareTo(ca);
          return b.createdAt.compareTo(a.createdAt);
        });
      case ProblemSortType.deadline:
        // Closest upcoming deadline first; problems without a deadline are
        // pushed to the tail (treated as +infinity).
        sorted.sort((a, b) {
          final DateTime? da = a.ideaSubmissionDeadline;
          final DateTime? db = b.ideaSubmissionDeadline;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
    }
    return sorted;
  }

  /// Lightweight natural-order compare so identifiers like "PS-2" sort
  /// before "PS-10". Splits the strings into alternating digit/non-digit
  /// runs and compares numerically when both sides are digit-only.
  static int _naturalCompare(String a, String b) {
    final RegExp re = RegExp(r'(\d+|\D+)');
    final List<String> pa = re.allMatches(a).map((m) => m.group(0)!).toList();
    final List<String> pb = re.allMatches(b).map((m) => m.group(0)!).toList();
    final int len = pa.length < pb.length ? pa.length : pb.length;
    for (int i = 0; i < len; i++) {
      final String sa = pa[i];
      final String sb = pb[i];
      final int? na = int.tryParse(sa);
      final int? nb = int.tryParse(sb);
      final int cmp = (na != null && nb != null) ? na.compareTo(nb) : sa.compareTo(sb);
      if (cmp != 0) return cmp;
    }
    return pa.length.compareTo(pb.length);
  }
}
