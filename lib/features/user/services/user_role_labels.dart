import '../models/enums/user_role.dart';

abstract final class UserRoleLabels {
  static String labelForCode(String roleCode) {
    return labelFor(UserRole.fromCode(roleCode));
  }

  static String labelFor(UserRole role) {
    return switch (role) {
      UserRole.sysAdmin => 'System Admin',
      UserRole.collegeAdmin => 'College Admin',
      UserRole.departmentAdmin => 'Department Admin',
      UserRole.faculty => 'Faculty',
      UserRole.judge => 'Judge',
      UserRole.coordinator => 'Coordinator',
      UserRole.student => 'Student',
    };
  }
}
