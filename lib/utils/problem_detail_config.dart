import '../models/enums/user_role.dart';
import '../models/user_model.dart';

enum ProblemIdeaScope {
  facultyOwn,
  teamOwn,
  department,
  org,
}

class ProblemDetailConfig {
  const ProblemDetailConfig({
    required this.canViewAllIdeas,
    required this.restrictToDepartment,
    required this.ideaScope,
  });

  final bool canViewAllIdeas;
  final bool restrictToDepartment;
  final ProblemIdeaScope ideaScope;
}

class ProblemDetailRoleConfig {
  ProblemDetailRoleConfig._();

  static ProblemDetailConfig configFor(UserModel user) {
    final role = UserRole.fromCode(user.role);
    switch (role) {
      case UserRole.faculty:
        return const ProblemDetailConfig(
          canViewAllIdeas: false,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.facultyOwn,
        );
      case UserRole.student:
        return const ProblemDetailConfig(
          canViewAllIdeas: false,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.teamOwn,
        );
      case UserRole.departmentAdmin:
        return const ProblemDetailConfig(
          canViewAllIdeas: true,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.department,
        );
      case UserRole.collegeAdmin:
        return const ProblemDetailConfig(
          canViewAllIdeas: true,
          restrictToDepartment: false,
          ideaScope: ProblemIdeaScope.org,
        );
      case UserRole.judge:
        return const ProblemDetailConfig(
          canViewAllIdeas: true,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.department,
        );
      case UserRole.coordinator:
        return const ProblemDetailConfig(
          canViewAllIdeas: false,
          restrictToDepartment: true,
          ideaScope: ProblemIdeaScope.department,
        );
      case UserRole.sysAdmin:
        return const ProblemDetailConfig(
          canViewAllIdeas: true,
          restrictToDepartment: false,
          ideaScope: ProblemIdeaScope.org,
        );
    }
  }
}
