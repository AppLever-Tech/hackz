enum ProblemFilterType {
  department,
  domain,
  status,
  source,
  tags,
  attachments,
}

enum ProblemSortType {
  newest,
  oldest,
  titleAZ,
  department,
  category,
  psNumber,
  ideasCount,
  deadline,
}

class ProblemListConfig {
  const ProblemListConfig({
    required this.canCreate,
    required this.canEdit,
    required this.canToggleActive,
    required this.canDeleteDraft,
    required this.canSubmitIdea,
    required this.canAssignJudge,
    required this.restrictToDepartment,
    required this.orgId,
    required this.departmentCode,
    required this.enabledFilters,
    required this.enabledSorts,
  });

  final bool canCreate;
  final bool canEdit;
  final bool canToggleActive;
  final bool canDeleteDraft;
  final bool canSubmitIdea;
  final bool canAssignJudge;
  final bool restrictToDepartment;
  final String orgId;
  final String departmentCode;
  final Set<ProblemFilterType> enabledFilters;
  final Set<ProblemSortType> enabledSorts;
}
