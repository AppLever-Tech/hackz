import 'package:flutter/material.dart';

import '../models/enums/organization_type.dart';
import '../models/enums/user_role.dart';

class AppIcons {
  AppIcons._();

  // Shared common action icons
  static const IconData add = Icons.add;
  static const IconData search = Icons.search;
  static const IconData refresh = Icons.refresh;
  static const IconData copy = Icons.copy;
  static const IconData copied = Icons.check;
  static const IconData key = Icons.key_outlined;
  static const IconData more = Icons.more_vert;

  // Shared domain icons
  static const IconData dashboard = Icons.grid_view_rounded;
  static const IconData organizations = Icons.apartment_outlined;
  static const IconData users = Icons.groups_outlined;
  static const IconData departments = Icons.groups_2_outlined;
  static const IconData problems = Icons.assignment_outlined;
  static const IconData ideas = Icons.lightbulb_outline;
  static const IconData insights = Icons.insights_outlined;
  static const IconData judges = Icons.gavel_outlined;
  static const IconData pendingUsers = Icons.how_to_reg_outlined;
  static const IconData payments = Icons.payments_outlined;
  static const IconData settings = Icons.settings_outlined;
  static const IconData scoring = Icons.score_outlined;
  static const IconData leaderboard = Icons.leaderboard_outlined;
  static const IconData submissions = Icons.upload_file_outlined;
  static const IconData results = Icons.insights_outlined;
  static const IconData verification = Icons.verified_user_outlined;
  static const IconData faculty = Icons.person_outline;
  static const IconData coordinator = Icons.manage_accounts_outlined;
  static const IconData student = Icons.school_outlined;
  static const IconData phone = Icons.phone_outlined;
  static const IconData email = Icons.email_outlined;
  static const IconData adminProfile = Icons.badge_outlined;

  static IconData forOrganizationType(OrganizationType? type) {
    switch (type) {
      case OrganizationType.college:
        return Icons.school_outlined;
      case OrganizationType.company:
        return Icons.business_outlined;
      case OrganizationType.researchInstitute:
        return Icons.science_outlined;
      case OrganizationType.trainingCenter:
        return Icons.cast_for_education_outlined;
      case null:
        return organizations;
    }
  }

  static IconData forUserRole(UserRole role) {
    switch (role) {
      case UserRole.sysAdmin:
        return settings;
      case UserRole.collegeAdmin:
        return organizations;
      case UserRole.departmentAdmin:
        return departments;
      case UserRole.faculty:
        return faculty;
      case UserRole.judge:
        return judges;
      case UserRole.student:
        return student;
      case UserRole.coordinator:
        return coordinator;
    }
  }

  static IconData forUserRoleCode(String roleCode) {
    final normalized = roleCode.trim().toUpperCase();
    switch (normalized) {
      case 'FAC':
        return faculty;
      case 'COO':
        return coordinator;
      case 'STU':
        return student;
      case 'SADM':
        return settings;
      case 'CADM':
        return organizations;
      case 'DADM':
        return departments;
      case 'JUD':
        return judges;
      default:
        return users;
    }
  }
}
