import '../../organization/models/department_model.dart';
import '../../../models/idea_model.dart';
import '../../../models/payment_model.dart';
import '../../../features/problems/models/problem_model.dart';
import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import '../../idea/services/idea_department_helpers.dart';

/// How idea lists/queries apply department scoping for a role.
enum IdeaDepartmentScope {
  /// Org-wide ideas only (e.g. judges).
  none,

  /// Innovation / submitter department ([IdeaModel.teamDepartmentCode]).
  teamDepartment,

  /// Finance / problem-owner department ([IdeaModel.problemDepartmentCode]).
  problemDepartment,
}

/// Centralized judge vs coordinator (and related) visibility rules.
abstract final class RoleVisibilityHelpers {
  /// Coordinators work on payments only — no idea lists, detail, or leaderboard idea views.
  static bool canViewIdeas(UserRole role) => role != UserRole.coordinator;

  static IdeaDepartmentScope ideaDepartmentScopeFor(UserRole role) {
    switch (role) {
      case UserRole.coordinator:
        return IdeaDepartmentScope.problemDepartment;
      case UserRole.departmentAdmin:
      case UserRole.student:
        return IdeaDepartmentScope.teamDepartment;
      case UserRole.judge:
      case UserRole.faculty:
      case UserRole.collegeAdmin:
      case UserRole.sysAdmin:
        return IdeaDepartmentScope.none;
    }
  }

  static String resolvedOrgId(UserModel user) => user.orgId.trim();

  static String resolvedDepartmentCode(UserModel user) => DepartmentModel.resolveCode(user.departmentCode);

  static bool matchesOrg(Map<String, dynamic> data, String orgId) {
    if (orgId.isEmpty) return false;
    return ((data['orgId'] as String?) ?? '').trim() == orgId;
  }

  static bool ideaMatchesOrg(IdeaModel idea, String orgId) {
    if (orgId.isEmpty) return false;
    return idea.orgId.trim() == orgId;
  }

  /// Judge: org-scoped ideas only. Coordinator: org + [problemDepartmentCode]. Others per [ideaDepartmentScopeFor].
  static bool ideaVisibleToUser(IdeaModel idea, UserModel user) {
    if (!ideaMatchesOrg(idea, resolvedOrgId(user))) return false;

    final role = UserRole.fromCode(user.role);
    if (role == UserRole.judge) return true;

    final dept = resolvedDepartmentCode(user);
    if (dept.isEmpty) return true;

    return switch (ideaDepartmentScopeFor(role)) {
      IdeaDepartmentScope.none => true,
      IdeaDepartmentScope.teamDepartment => IdeaDepartmentHelpers.ideaMatchesTeamDept(idea, dept),
      IdeaDepartmentScope.problemDepartment => IdeaDepartmentHelpers.ideaMatchesProblemDept(idea, dept),
    };
  }

  static bool ideaMapVisibleToUser(Map<String, dynamic> map, UserModel user) {
    if (!matchesOrg(map, resolvedOrgId(user))) return false;

    final role = UserRole.fromCode(user.role);
    if (role == UserRole.judge) return true;

    final dept = resolvedDepartmentCode(user);
    if (dept.isEmpty) return true;

    return switch (ideaDepartmentScopeFor(role)) {
      IdeaDepartmentScope.none => true,
      IdeaDepartmentScope.teamDepartment => IdeaDepartmentHelpers.matchesTeamDept(map, dept),
      IdeaDepartmentScope.problemDepartment => IdeaDepartmentHelpers.matchesProblemDept(map, dept),
    };
  }

  static bool ideaMatchesDepartmentScope(IdeaModel idea, IdeaDepartmentScope scope, String departmentCode) {
    final dept = DepartmentModel.resolveCode(departmentCode);
    if (dept.isEmpty) return true;
    return switch (scope) {
      IdeaDepartmentScope.none => true,
      IdeaDepartmentScope.teamDepartment => IdeaDepartmentHelpers.ideaMatchesTeamDept(idea, dept),
      IdeaDepartmentScope.problemDepartment => IdeaDepartmentHelpers.ideaMatchesProblemDept(idea, dept),
    };
  }

  static String ideaDepartmentCodeForScope(IdeaModel idea, IdeaDepartmentScope scope) {
    return switch (scope) {
      IdeaDepartmentScope.problemDepartment => idea.problemDepartmentCode,
      IdeaDepartmentScope.teamDepartment => idea.teamDepartmentCode,
      IdeaDepartmentScope.none => '',
    };
  }

  static String? ideaFirestoreDepartmentFieldForScope(IdeaDepartmentScope scope) {
    return switch (scope) {
      IdeaDepartmentScope.teamDepartment => IdeaModel.fieldTeamDepartmentCode,
      IdeaDepartmentScope.problemDepartment => IdeaModel.fieldProblemDepartmentCode,
      IdeaDepartmentScope.none => null,
    };
  }

  static String? ideaFirestoreDepartmentFieldForRole(UserRole role) =>
      ideaFirestoreDepartmentFieldForScope(ideaDepartmentScopeFor(role));

  static bool paymentVisibleToCoordinator(PaymentModel payment, UserModel coordinator) {
    if (payment.orgId.trim() != resolvedOrgId(coordinator)) return false;
    final dept = resolvedDepartmentCode(coordinator);
    if (dept.isEmpty) return true;
    return DepartmentModel.resolveCode(payment.departmentCode) == dept;
  }

  static bool paymentMapVisibleToCoordinator(Map<String, dynamic> map, UserModel coordinator) {
    if (!matchesOrg(map, resolvedOrgId(coordinator))) return false;
    final dept = resolvedDepartmentCode(coordinator);
    if (dept.isEmpty) return true;
    return DepartmentModel.resolveCode((map['departmentCode'] as String?) ?? '') == dept;
  }

  static bool problemVisibleToCoordinator(ProblemModel problem, UserModel coordinator) {
    if (problem.orgId.trim() != resolvedOrgId(coordinator)) return false;
    final dept = resolvedDepartmentCode(coordinator);
    if (dept.isEmpty) return true;
    return DepartmentModel.resolveCode(problem.departmentCode) == dept;
  }

  static bool problemMapVisibleToCoordinator(Map<String, dynamic> map, UserModel coordinator) {
    if (!matchesOrg(map, resolvedOrgId(coordinator))) return false;
    final dept = resolvedDepartmentCode(coordinator);
    if (dept.isEmpty) return true;
    return DepartmentModel.resolveCode((map['departmentCode'] as String?) ?? '') == dept;
  }
}
