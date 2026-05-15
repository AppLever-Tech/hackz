import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import 'role_visibility_helpers.dart';

enum ProblemIdeaScope {
  facultyOwn,
  teamOwn,
  department,
  problemDepartment,
  org,
}

class ProblemDetailConfig {
  const ProblemDetailConfig({
    required this.canViewIdeas,
    required this.canViewAllIdeas,
    required this.restrictToDepartment,
    required this.ideaScope,
  });

  final bool canViewIdeas;
  final bool canViewAllIdeas;
  final bool restrictToDepartment;
  final ProblemIdeaScope ideaScope;
}

class ProblemDetailRoleConfig {
  ProblemDetailRoleConfig._();

  static ProblemDetailConfig configFor(UserModel user) {
    final role = UserRole.fromCode(user.role);
    final canViewIdeas = RoleVisibilityHelpers.canViewIdeas(role);
    switch (role) {
      case UserRole.faculty:
        return ProblemDetailConfig(
          canViewIdeas: canViewIdeas,
          canViewAllIdeas: false,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.facultyOwn,
        );
      case UserRole.student:
        return ProblemDetailConfig(
          canViewIdeas: canViewIdeas,
          canViewAllIdeas: false,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.teamOwn,
        );
      case UserRole.departmentAdmin:
        return ProblemDetailConfig(
          canViewIdeas: canViewIdeas,
          canViewAllIdeas: true,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.department,
        );
      case UserRole.collegeAdmin:
        return ProblemDetailConfig(
          canViewIdeas: canViewIdeas,
          canViewAllIdeas: true,
          restrictToDepartment: false,
          ideaScope: ProblemIdeaScope.org,
        );
      case UserRole.judge:
        return ProblemDetailConfig(
          canViewIdeas: canViewIdeas,
          canViewAllIdeas: true,
          restrictToDepartment: false,
          ideaScope: ProblemIdeaScope.org,
        );
      case UserRole.coordinator:
        return const ProblemDetailConfig(
          canViewIdeas: false,
          canViewAllIdeas: false,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.problemDepartment,
        );
      case UserRole.sysAdmin:
        return ProblemDetailConfig(
          canViewIdeas: canViewIdeas,
          canViewAllIdeas: true,
          restrictToDepartment: false,
          ideaScope: ProblemIdeaScope.org,
        );
    }
  }
}
