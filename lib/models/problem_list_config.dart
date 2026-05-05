enum ProblemFilterType {
  department,
  status,
  tags,
  attachments,
}

enum ProblemSortType {
  newest,
  oldest,
  titleAZ,
  department,
}

class ProblemListConfig {
  const ProblemListConfig({
    required this.canCreate,
    required this.canEdit,
    required this.canToggleActive,
    required this.restrictToDepartment,
    required this.orgId,
    required this.departmentCode,
    required this.enabledFilters,
    required this.enabledSorts,
  });

  final bool canCreate;
  final bool canEdit;
  final bool canToggleActive;
  final bool restrictToDepartment;
  final String orgId;
  final String departmentCode;
  final Set<ProblemFilterType> enabledFilters;
  final Set<ProblemSortType> enabledSorts;
}
