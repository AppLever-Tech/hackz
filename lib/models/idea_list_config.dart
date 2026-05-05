enum IdeaFilterType {
  status,
  problem,
  department,
}

enum IdeaSortType {
  newest,
  oldest,
  status,
  score,
}

class IdeaListConfig {
  const IdeaListConfig({
    required this.canCreateIdea,
    required this.canEvaluate,
    required this.canViewStatus,
    required this.canUploadPayment,
    required this.restrictToDepartment,
    required this.orgId,
    required this.departmentCode,
    required this.enabledFilters,
    required this.enabledSorts,
  });

  final bool canCreateIdea;
  final bool canEvaluate;
  final bool canViewStatus;
  final bool canUploadPayment;
  final bool restrictToDepartment;
  final String orgId;
  final String departmentCode;
  final Set<IdeaFilterType> enabledFilters;
  final Set<IdeaSortType> enabledSorts;
}
