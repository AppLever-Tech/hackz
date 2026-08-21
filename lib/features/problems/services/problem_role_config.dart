import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../models/problem_list_config.dart';

class ProblemRoleConfig {
  ProblemRoleConfig._();

  static ProblemListConfig configFor(UserRole role, UserModel user, {bool teamLeader = false}) {
    switch (role) {
      case UserRole.collegeAdmin:
        return ProblemListConfig(
          canCreate: true,
          canEdit: true,
          canToggleActive: true,
          canDeleteDraft: true,
          canSubmitIdea: false,
          canAssignJudge: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.department,
            ProblemFilterType.domain,
            ProblemFilterType.status,
            ProblemFilterType.source,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.psNumber,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
            ProblemSortType.category,
            ProblemSortType.ideasCount,
            ProblemSortType.deadline,
          },
        );
      case UserRole.departmentAdmin:
        return ProblemListConfig(
          canCreate: true,
          canEdit: true,
          canToggleActive: false,
          canDeleteDraft: true,
          canSubmitIdea: false,
          // Phase 1: pre-Ideathon judge assignment removed; infrastructure kept for Ideathon phases.
          canAssignJudge: false,
          // All problem statements should be shown for department admin, faculty, and student views.
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.domain,
            ProblemFilterType.status,
            ProblemFilterType.source,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.psNumber,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
            ProblemSortType.category,
            ProblemSortType.ideasCount,
            ProblemSortType.deadline,
          },
        );
      case UserRole.faculty:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canDeleteDraft: false,
          canSubmitIdea: true,
          canAssignJudge: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.domain,
            ProblemFilterType.status,
            ProblemFilterType.source,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.psNumber,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
            ProblemSortType.category,
            ProblemSortType.ideasCount,
            ProblemSortType.deadline,
          },
        );
      case UserRole.student:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canDeleteDraft: false,
          canSubmitIdea: teamLeader,
          canAssignJudge: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.domain,
            ProblemFilterType.status,
            ProblemFilterType.source,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.psNumber,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
            ProblemSortType.category,
            ProblemSortType.ideasCount,
            ProblemSortType.deadline,
          },
        );
      case UserRole.coordinator:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canDeleteDraft: false,
          canSubmitIdea: false,
          canAssignJudge: false,
          restrictToDepartment: true,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.domain,
            ProblemFilterType.status,
            ProblemFilterType.source,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.psNumber,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
            ProblemSortType.category,
            ProblemSortType.ideasCount,
            ProblemSortType.deadline,
          },
        );
      case UserRole.judge:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canDeleteDraft: false,
          canSubmitIdea: false,
          canAssignJudge: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.department,
            ProblemFilterType.domain,
            ProblemFilterType.status,
            ProblemFilterType.source,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.psNumber,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
            ProblemSortType.category,
            ProblemSortType.ideasCount,
            ProblemSortType.deadline,
          },
        );
      case UserRole.sysAdmin:
        return ProblemListConfig(
          canCreate: false,
          canEdit: false,
          canToggleActive: false,
          canDeleteDraft: false,
          canSubmitIdea: false,
          canAssignJudge: false,
          restrictToDepartment: false,
          orgId: user.orgId,
          departmentCode: user.departmentCode,
          enabledFilters: const <ProblemFilterType>{
            ProblemFilterType.department,
            ProblemFilterType.domain,
            ProblemFilterType.status,
            ProblemFilterType.source,
            ProblemFilterType.tags,
            ProblemFilterType.attachments,
          },
          enabledSorts: const <ProblemSortType>{
            ProblemSortType.newest,
            ProblemSortType.oldest,
            ProblemSortType.psNumber,
            ProblemSortType.titleAZ,
            ProblemSortType.department,
            ProblemSortType.category,
            ProblemSortType.ideasCount,
            ProblemSortType.deadline,
          },
        );
    }
  }
}
