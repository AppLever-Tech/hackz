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
      UserRole.judge => 'Judge',
      UserRole.coordinator => 'Coordinator',
      UserRole.teamMember => 'Team Member',
    };
  }

  static String pluralLabelForCode(String roleCode) {
    return pluralLabelFor(UserRole.fromCode(roleCode));
  }

  static String pluralLabelFor(UserRole role) {
    return switch (role) {
      UserRole.sysAdmin => 'System Admins',
      UserRole.collegeAdmin => 'College Admins',
      UserRole.departmentAdmin => 'Department Admins',
      UserRole.judge => 'Judges',
      UserRole.coordinator => 'Coordinators',
      UserRole.teamMember => 'Team Members',
    };
  }
}
