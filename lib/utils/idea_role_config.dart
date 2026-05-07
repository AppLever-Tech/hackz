import '../models/enums/user_role.dart';
import '../models/idea_list_config.dart';
import '../models/user_model.dart';

class IdeaRoleConfig {
  IdeaRoleConfig._();

  static IdeaListConfig configFor(UserRole role, UserModel user) {
    switch (role) {
      case UserRole.faculty:
        return IdeaListConfig(
          canCreateIdea: true,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: true,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <IdeaFilterType>{
            IdeaFilterType.status,
            IdeaFilterType.problem,
          },
          enabledSorts: const <IdeaSortType>{
            IdeaSortType.newest,
            IdeaSortType.oldest,
            IdeaSortType.status,
          },
        );
      case UserRole.judge:
        return IdeaListConfig(
          canCreateIdea: false,
          canEvaluate: true,
          canViewStatus: true,
          canUploadPayment: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <IdeaFilterType>{
            IdeaFilterType.status,
            IdeaFilterType.problem,
            IdeaFilterType.department,
          },
          enabledSorts: const <IdeaSortType>{
            IdeaSortType.newest,
            IdeaSortType.oldest,
            IdeaSortType.status,
            IdeaSortType.score,
          },
        );
      case UserRole.collegeAdmin:
      case UserRole.departmentAdmin:
        return IdeaListConfig(
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: false,
          restrictToDepartment: true,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <IdeaFilterType>{
            IdeaFilterType.status,
            IdeaFilterType.problem,
          },
          enabledSorts: const <IdeaSortType>{
            IdeaSortType.newest,
            IdeaSortType.oldest,
            IdeaSortType.status,
          },
        );
      case UserRole.student:
        return IdeaListConfig(
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: true,
          restrictToDepartment: true,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <IdeaFilterType>{
            IdeaFilterType.status,
            IdeaFilterType.problem,
          },
          enabledSorts: const <IdeaSortType>{
            IdeaSortType.newest,
            IdeaSortType.oldest,
            IdeaSortType.status,
          },
        );
      case UserRole.sysAdmin:
        return IdeaListConfig(
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <IdeaFilterType>{
            IdeaFilterType.status,
            IdeaFilterType.problem,
            IdeaFilterType.department,
          },
          enabledSorts: const <IdeaSortType>{
            IdeaSortType.newest,
            IdeaSortType.oldest,
            IdeaSortType.status,
            IdeaSortType.score,
          },
        );
      case UserRole.coordinator:
        return IdeaListConfig(
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: false,
          restrictToDepartment: true,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <IdeaFilterType>{
            IdeaFilterType.status,
            IdeaFilterType.problem,
            IdeaFilterType.department,
          },
          enabledSorts: const <IdeaSortType>{
            IdeaSortType.newest,
            IdeaSortType.oldest,
            IdeaSortType.status,
          },
        );
    }
  }
}
