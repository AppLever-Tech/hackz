import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/coordinator_dashboard_service.dart';
import '../../utils/department_dashboard_service.dart';
import '../../utils/faculty_teams_service.dart';
import '../../utils/judge_evaluation_service.dart';
import '../../utils/platform_settings_service.dart';
import '../../utils/sysadmin_dashboard_service.dart';
import '../../widgets/responsive/responsive_dashboard_layout.dart';
import '../auth/landing_screen.dart';
import 'dashboard_components.dart';

class DashboardPageTemplate extends StatefulWidget {
  const DashboardPageTemplate({
    super.key,
    required this.user,
    required this.bodyBuilder,
  });

  final UserModel user;
  final Widget Function(
    BuildContext context,
    int refreshToken,
    int selectedMenuIndex,
  ) bodyBuilder;

  @override
  State<DashboardPageTemplate> createState() => _DashboardPageTemplateState();
}

class _DashboardPageTemplateState extends State<DashboardPageTemplate> {
  int _refreshToken = 0;
  int _selectedPrimaryMenuIndex = 0;

  String _roleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.sysAdmin:
        return 'System Administrator';
      case UserRole.collegeAdmin:
        return 'College Administrator';
      case UserRole.departmentAdmin:
        return 'Department Administrator';
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.judge:
        return 'Judge';
      case UserRole.student:
        return 'Student';
      case UserRole.coordinator:
        return 'Coordinator';
    }
  }

  String _formatLongDate(DateTime date) {
    const weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _logout(BuildContext context) async {
    PlatformSettingsService.instance.clearCache();
    SysAdminDashboardService.clearCache();
    DepartmentDashboardService.clearCache();
    FacultyTeamsService.clearCache();
    CoordinatorDashboardService.clearCache();
    JudgeEvaluationService.clearCache();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserRole role = UserRole.fromCode(widget.user.role);
    final _RoleMenuConfig menuConfig = _RoleMenuConfig.forRole(role);
    final String fullName =
        '${widget.user.firstName} ${widget.user.lastName}'.trim().isEmpty
            ? 'User'
            : '${widget.user.firstName} ${widget.user.lastName}'.trim();
    final String dashboardTitle = '$fullName\'s Dashboard';
    final String roleName = _roleDisplayName(role);
    final String longDate = _formatLongDate(DateTime.now());
    final bool isDashboardTab = _selectedPrimaryMenuIndex == 0;
    final String selectedMenuTitle = menuConfig.primaryMenus[_selectedPrimaryMenuIndex].label;
    final IconData selectedMenuIcon = menuConfig.primaryMenus[_selectedPrimaryMenuIndex].icon;

    return ResponsiveDashboardLayout(
      primaryMenus: menuConfig.primaryMenus,
      secondaryMenus: menuConfig.secondaryMenus,
      selectedPrimaryIndex: _selectedPrimaryMenuIndex,
      onPrimaryMenuSelected: (int index) => setState(() => _selectedPrimaryMenuIndex = index),
      onLogout: () => _logout(context),
      header: TopHeaderWidget(
        title: isDashboardTab ? dashboardTitle : selectedMenuTitle,
        titleIcon: selectedMenuIcon,
        subtitle: isDashboardTab ? roleName : '',
        dateText: longDate,
        onRefresh: () => setState(() => _refreshToken++),
      ),
      body: widget.bodyBuilder(
        context,
        _refreshToken,
        _selectedPrimaryMenuIndex,
      ),
    );
  }
}

class _RoleMenuConfig {
  const _RoleMenuConfig({
    required this.primaryMenus,
    required this.secondaryMenus,
  });

  final List<DashboardMenuItem> primaryMenus;
  final List<DashboardMenuItem> secondaryMenus;

  static _RoleMenuConfig forRole(UserRole role) {
    switch (role) {
      case UserRole.sysAdmin:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
            DashboardMenuItem(label: 'Organizations', icon: AppIcons.organizations),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
            DashboardMenuItem(label: 'Platform settings', icon: AppIcons.platformSettings),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.collegeAdmin:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Manage College', icon: AppIcons.organizations),
            DashboardMenuItem(label: 'Problem Statements', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas Dashboard', icon: AppIcons.insights),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.departmentAdmin:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Manage Department', icon: AppIcons.departments),
            DashboardMenuItem(label: 'Problem Statements', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas Dashboard', icon: AppIcons.insights),
            DashboardMenuItem(label: 'Judges Panel', icon: AppIcons.judges),
            DashboardMenuItem(label: 'Payments', icon: AppIcons.payments),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.faculty:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Teams', icon: AppIcons.users),
            DashboardMenuItem(label: 'Problems', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas', icon: AppIcons.ideas),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.judge:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Scoring', icon: AppIcons.scoring),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.student:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Problems', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas', icon: AppIcons.ideas),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.coordinator:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Payment Verification', icon: AppIcons.verification),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
    }
  }
}
