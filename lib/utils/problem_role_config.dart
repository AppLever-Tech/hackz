import '../models/enums/user_role.dart';
import '../models/problem_list_config.dart';
import '../models/user_model.dart';

class ProblemRoleConfig {
  ProblemRoleConfig._();

  static ProblemListConfig configFor(UserRole role, UserModel user) {
    switch (role) {
      case UserRole.collegeAdmin:
        return ProblemListConfig(
          canCreate: true,
          canEdit: true,
          canToggleActive: true,
          canSubmitIdea: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.department,
            ProblemFilterType.status,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
          },
        );
      case UserRole.departmentAdmin:
        return ProblemListConfig(
          canCreate: true,
          canEdit: true,
          canToggleActive: false,
          canSubmitIdea: false,
          // All problem statements should be shown for department admin, faculty, and student views.
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.status,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.titleAZ,
          },
        );
      case UserRole.faculty:
      case UserRole.student:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canSubmitIdea: true,
          // All problem statements should be shown for department admin, faculty, and student views.
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.status,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.titleAZ,
          },
        );
      case UserRole.coordinator:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canSubmitIdea: false,
          restrictToDepartment: true,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.status,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.titleAZ,
          },
        );
      case UserRole.judge:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canSubmitIdea: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.department,
            ProblemFilterType.status,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
          },
        );
      case UserRole.sysAdmin:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canSubmitIdea: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.department,
            ProblemFilterType.status,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
          },
        );
    }
  }
}
