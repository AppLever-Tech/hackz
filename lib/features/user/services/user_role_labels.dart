import '../models/enums/user_role.dart';

abstract final class UserRoleLabels {
  static String labelForCode(String roleCode) {
    return labelFor(UserRole.fromCode(roleCode));
  }

  static String labelFor(UserRole role) {
    return switch (role) {
      UserRole.sysAdmin => 'System Admin',
      UserRole.orgAdmin => 'Hackz Organisation Admin',
      UserRole.collegeAdmin => 'College Admin',
      UserRole.departmentAdmin => 'Department Admin',
      UserRole.judge => 'Judge',
      UserRole.coordinator => 'Coordinator',
      UserRole.teamMember => 'Team Member',
    };
  }

  /// Shorter labels for dashboard page header identity pills.
  static String headerLabelFor(UserRole role) {
    return switch (role) {
      UserRole.sysAdmin => 'SysAdmin',
      UserRole.orgAdmin => 'Org Admin',
      UserRole.collegeAdmin => 'College Admin',
      UserRole.departmentAdmin => 'Department Admin',
      UserRole.judge => 'Judge',
      UserRole.coordinator => 'Coordinator',
      UserRole.teamMember => 'Team Member',
    };
  }

  static String headerLabelForCode(String roleCode) {
    return headerLabelFor(UserRole.fromCode(roleCode));
  }

  static String pluralLabelForCode(String roleCode) {
    return pluralLabelFor(UserRole.fromCode(roleCode));
  }

  static String pluralLabelFor(UserRole role) {
    return switch (role) {
      UserRole.sysAdmin => 'System Admins',
      UserRole.orgAdmin => 'Hackz Organisation Admins',
      UserRole.collegeAdmin => 'College Admins',
      UserRole.departmentAdmin => 'Department Admins',
      UserRole.judge => 'Judges',
      UserRole.coordinator => 'Coordinators',
      UserRole.teamMember => 'Team Members',
    };
  }
}
