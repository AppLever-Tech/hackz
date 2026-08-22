import 'package:flutter/material.dart';

import '../../../features/dashboard/collegeadmin/screens/collegeadmin_dashboard.dart';
import '../../../features/dashboard/coordinator/screens/coordinator_dashboard.dart';
import '../../../features/dashboard/deptadmin/screens/deptadmin_dashboard.dart';
import '../../../features/dashboard/judge/screens/judge_dashboard.dart';
import '../../../features/dashboard/team_member/screens/team_member_dashboard.dart';
import '../../../features/dashboard/sysadmin/screens/sysadmin_dashboard.dart';
import '../models/enums/user_role.dart';
import '../models/user_model.dart';

class RoleUtils {
  RoleUtils._();

  static UserRole toEnum(String roleCode) {
    return UserRole.fromCode(roleCode);
  }

  static Widget routeForRole(UserModel user) {
    if (user.hasRoleCode(UserRole.judge.code)) {
      return JudgeDashboard(user: user);
    }
    switch (toEnum(user.role)) {
      case UserRole.sysAdmin:
        return SysAdminDashboard(user: user);
      case UserRole.collegeAdmin:
        return CollegeAdminDashboard(user: user);
      case UserRole.departmentAdmin:
        return DeptAdminDashboard(user: user);
      case UserRole.teamMember:
        return TeamMemberDashboard(user: user);
      case UserRole.judge:
        return JudgeDashboard(user: user);
      case UserRole.coordinator:
        return CoordinatorDashboard(user: user);
    }
  }
}
