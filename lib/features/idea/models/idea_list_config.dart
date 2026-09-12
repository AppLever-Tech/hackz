import '../../user/services/role_visibility_helpers.dart';

enum IdeaFilterType {
  status,
  problem,
  department,
}

enum IdeaSortType {
  newest,
  oldest,
  status,
}

class IdeaListConfig {
  const IdeaListConfig({
    required this.canViewIdeas,
    required this.canCreateIdea,
    required this.canEvaluate,
    required this.canViewStatus,
    required this.canUploadPayment,
    required this.canAssignJudge,
    required this.ideaDepartmentScope,
    required this.orgId,
    required this.departmentCode,
    required this.enabledFilters,
    required this.enabledSorts,
  });

  final bool canViewIdeas;
  final bool canCreateIdea;
  final bool canEvaluate;
  final bool canViewStatus;
  final bool canUploadPayment;
  final bool canAssignJudge;
  final IdeaDepartmentScope ideaDepartmentScope;
  final String orgId;
  final String departmentCode;
  final Set<IdeaFilterType> enabledFilters;
  final Set<IdeaSortType> enabledSorts;

  IdeaListConfig copyWith({bool? canUploadPayment}) {
    return IdeaListConfig(
      canViewIdeas: canViewIdeas,
      canCreateIdea: canCreateIdea,
      canEvaluate: canEvaluate,
      canViewStatus: canViewStatus,
      canUploadPayment: canUploadPayment ?? this.canUploadPayment,
      canAssignJudge: canAssignJudge,
      ideaDepartmentScope: ideaDepartmentScope,
      orgId: orgId,
      departmentCode: departmentCode,
      enabledFilters: enabledFilters,
      enabledSorts: enabledSorts,
    );
  }
}
