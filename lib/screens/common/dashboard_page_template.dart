import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../features/user/models/enums/user_role.dart';
import '../../features/user/models/user_model.dart';
import '../../utils/coordinator_dashboard_service.dart';
import '../../utils/department_dashboard_service.dart';
import '../../features/team/services/faculty_teams_service.dart';
import '../../features/org_settings/services/org_settings_service.dart';
import '../../utils/judge_evaluation_service.dart';
import '../../utils/sysadmin_dashboard_service.dart';
import '../../widgets/responsive/responsive_dashboard_layout.dart';
import '../../workspace/workspace.dart';
import '../auth/landing_screen.dart';
import 'dashboard_chrome_controller.dart';
import 'dashboard_chrome_scope.dart';
import 'dashboard_components.dart';
import 'dashboard_session_scope.dart';

class DashboardPageTemplate extends StatefulWidget {
  const DashboardPageTemplate({
    super.key,
    required this.user,
    required this.bodyBuilder,
    this.primaryMenusOverride,
  });

  final UserModel user;
  final Widget Function(
    BuildContext context,
    int refreshToken,
    int selectedMenuIndex,
  ) bodyBuilder;

  /// When set, replaces the role-default primary navigation items.
  final List<DashboardMenuItem>? primaryMenusOverride;

  @override
  State<DashboardPageTemplate> createState() => _DashboardPageTemplateState();
}

class _DashboardPageTemplateState extends State<DashboardPageTemplate> {
  int _refreshToken = 0;
  int _selectedPrimaryMenuIndex = 0;
  final DashboardChromeController _chromeController = DashboardChromeController();

  @override
  void dispose() {
    _chromeController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    WorkspaceController.instance.close();
    _chromeController.clearOverlay();
    OrgSettingsService.instance.clearCache();
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
    final List<DashboardMenuItem> primaryMenus =
        widget.primaryMenusOverride ?? menuConfig.primaryMenus;
    final String selectedMenuTitle = primaryMenus[_selectedPrimaryMenuIndex].label;
    final IconData selectedMenuIcon = primaryMenus[_selectedPrimaryMenuIndex].icon;
    final bool isDashboardTab = _selectedPrimaryMenuIndex == 0;

    return DashboardSessionScope(
      user: widget.user,
      onLogout: () => _logout(context),
      child: DashboardChromeScope(
        controller: _chromeController,
        child: ListenableBuilder(
          listenable: _chromeController,
          builder: (BuildContext context, Widget? child) {
            return ResponsiveDashboardLayout(
            primaryMenus: primaryMenus,
            secondaryMenus: menuConfig.secondaryMenus,
            selectedPrimaryIndex: _selectedPrimaryMenuIndex,
            onPrimaryMenuSelected: (int index) {
              if (index != _selectedPrimaryMenuIndex) {
                WorkspaceController.instance.close();
                _chromeController.clearOverlay();
              }
              setState(() => _selectedPrimaryMenuIndex = index);
            },
            header: DashboardPageHeader(
              title: isDashboardTab ? 'Dashboard' : selectedMenuTitle,
              titleIcon: selectedMenuIcon,
              user: widget.user,
              onLogout: () => _logout(context),
              onUserTap: () => WorkspaceNavigator.openUser(context, widget.user.userId),
              onRefresh: () {
                _chromeController.clearOverlay();
                setState(() => _refreshToken++);
              },
            ),
            body: widget.bodyBuilder(
              context,
              _refreshToken,
              _selectedPrimaryMenuIndex,
            ),
              panelOverlay: _chromeController.overlay,
            );
          },
        ),
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
            DashboardMenuItem(label: 'Org Settings', icon: AppIcons.orgSettings),
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
            DashboardMenuItem(label: 'Evaluation Results', icon: AppIcons.results),
            DashboardMenuItem(label: 'Evaluation Extensions', icon: AppIcons.scoring),
            DashboardMenuItem(label: 'Judges Panel', icon: AppIcons.judges),
            DashboardMenuItem(label: 'Payments', icon: AppIcons.payments),
            DashboardMenuItem(label: 'Requests', icon: Icons.inbox_rounded),
            DashboardMenuItem(label: 'Leaderboard', icon: AppIcons.leaderboard),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.faculty:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Teams', icon: AppIcons.users),
            DashboardMenuItem(label: 'Problem Statements', icon: AppIcons.problems),
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
