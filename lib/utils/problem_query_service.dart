import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/problem_list_config.dart';
import '../models/problem_model.dart';
import 'firestore_utils.dart';

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

class ProblemQueryService {
  ProblemQueryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<ProblemModel>> fetchProblems(ProblemQueryParams params) async {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestoreUtils.hkzProblems)
        .where('orgId', isEqualTo: params.config.orgId);

    final snapshot = await query.limit(params.limit).get();
    var items = snapshot.docs
        .map((doc) => ProblemModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    items = _applyFilters(items, params);
    items = _applySort(items, params.sortType);
    return items;
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
      if (params.hasAttachments != null) {
        final hasAny = problem.attachments.isNotEmpty;
        if (hasAny != params.hasAttachments) {
          return false;
        }
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

  static List<ProblemModel> _applySort(List<ProblemModel> items, ProblemSortType sortType) {
    final sorted = List<ProblemModel>.from(items);
    switch (sortType) {
      case ProblemSortType.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ProblemSortType.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ProblemSortType.titleAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case ProblemSortType.department:
        sorted.sort((a, b) => a.departmentCode.toLowerCase().compareTo(b.departmentCode.toLowerCase()));
    }
    return sorted;
  }
}
