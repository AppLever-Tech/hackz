import 'package:flutter/material.dart';

import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import '../screens/collegeadmin/collegeadmin_dashboard.dart';
import '../screens/coordinator/coordinator_dashboard.dart';
import '../screens/deptadmin/deptadmin_dashboard.dart';
import '../screens/faculty/faculty_dashboard.dart';
import '../screens/judge/judge_dashboard.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/sysadmin/sysadmin_dashboard.dart';

class RoleUtils {
  RoleUtils._();

  static UserRole toEnum(String roleCode) {
    return UserRole.fromCode(roleCode);
  }

  static Widget routeForRole(UserModel user) {
    switch (toEnum(user.role)) {
      case UserRole.sysAdmin:
        return SysAdminDashboard(user: user);
      case UserRole.collegeAdmin:
        return CollegeAdminDashboard(user: user);
      case UserRole.departmentAdmin:
        return DeptAdminDashboard(user: user);
      case UserRole.faculty:
        return FacultyDashboard(user: user);
      case UserRole.student:
        return StudentDashboard(user: user);
      case UserRole.judge:
        return JudgeDashboard(user: user);
      case UserRole.coordinator:
        return CoordinatorDashboard(user: user);
    }
  }
}
