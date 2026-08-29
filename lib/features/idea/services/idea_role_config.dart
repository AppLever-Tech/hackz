import '../../user/models/enums/user_role.dart';
import '../models/idea_list_config.dart';
import '../../user/models/user_model.dart';
import '../../user/services/role_visibility_helpers.dart';

class IdeaRoleConfig {
  IdeaRoleConfig._();

  static IdeaListConfig configFor(UserRole role, UserModel user, {bool teamLeader = false}) {
    final scope = RoleVisibilityHelpers.ideaDepartmentScopeFor(role);
    final canViewIdeas = RoleVisibilityHelpers.canViewIdeas(role);
    switch (role) {
      case UserRole.judge:
        return IdeaListConfig(
          canViewIdeas: canViewIdeas,
          canCreateIdea: false,
          canEvaluate: true,
          canViewStatus: true,
          canUploadPayment: false,
          canAssignJudge: false,
          ideaDepartmentScope: scope,
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
      case UserRole.collegeAdmin:
        return IdeaListConfig(
          canViewIdeas: canViewIdeas,
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: false,
          canAssignJudge: false,
          ideaDepartmentScope: scope,
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
      case UserRole.departmentAdmin:
        return IdeaListConfig(
          canViewIdeas: canViewIdeas,
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: false,
          canAssignJudge: false,
          ideaDepartmentScope: scope,
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
      case UserRole.teamMember:
        return IdeaListConfig(
          canViewIdeas: canViewIdeas,
          canCreateIdea: teamLeader,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: teamLeader,
          canAssignJudge: false,
          ideaDepartmentScope: scope,
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
          canViewIdeas: canViewIdeas,
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: true,
          canUploadPayment: false,
          canAssignJudge: false,
          ideaDepartmentScope: scope,
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
      case UserRole.coordinator:
        return IdeaListConfig(
          canViewIdeas: false,
          canCreateIdea: false,
          canEvaluate: false,
          canViewStatus: false,
          canUploadPayment: false,
          canAssignJudge: false,
          ideaDepartmentScope: scope,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <IdeaFilterType>{},
          enabledSorts: const <IdeaSortType>{},
        );
    }
  }
}
