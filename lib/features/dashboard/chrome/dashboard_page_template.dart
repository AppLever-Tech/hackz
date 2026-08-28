import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/user/models/enums/user_role.dart';
import '../../../features/user/models/user_model.dart';
import '../coordinator/services/coordinator_dashboard_service.dart';
import '../deptadmin/services/department_dashboard_service.dart';
import '../../../features/team/services/teams_workspace_service.dart';
import '../../../features/org_settings/services/org_settings_service.dart';
import '../../../features/evaluations/services/judge_evaluation_service.dart';
import '../sysadmin/services/sysadmin_dashboard_service.dart';
import '../../../core/responsive/responsive_dashboard_layout.dart';
import '../../../features/auth/screens/landing_screen.dart';
import '../../../features/docs/data/docs_registry.dart';
import '../../../core/ui/common/page_header_context_pill.dart';
import 'dashboard_chrome_controller.dart';
import 'dashboard_chrome_scope.dart';
import 'dashboard_components.dart';
import 'dashboard_session_scope.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

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
    TeamsWorkspaceService.clearCache();
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
                _chromeController.setHeaderContextPills(const <PageHeaderContextItem>[]);
              }
              setState(() => _selectedPrimaryMenuIndex = index);
            },
            header: DashboardPageHeader(
              title: isDashboardTab ? 'Dashboard' : selectedMenuTitle,
              titleIcon: selectedMenuIcon,
              contextPills: _chromeController.headerContextPills,
              user: widget.user,
              onLogout: () => _logout(context),
              onUserTap: () => WorkspaceNavigator.openUser(context, widget.user.userId),
              helpPageId: isDashboardTab
                  ? null
                  : DocsRegistry.helpPageForContext(selectedMenuTitle),
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
            DashboardMenuItem(label: 'App Metadata', icon: AppIcons.info),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.collegeAdmin:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Manage College', icon: AppIcons.organizations),
            DashboardMenuItem(label: 'Domains', icon: AppIcons.domains),
            DashboardMenuItem(label: 'Problem Statements', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas Dashboard', icon: AppIcons.insights),
            DashboardMenuItem(label: 'Org Settings', icon: AppIcons.orgSettings),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.departmentAdmin:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'People & Teams', icon: AppIcons.users),
            DashboardMenuItem(label: 'Domains', icon: AppIcons.domains),
            DashboardMenuItem(label: 'Problem Statements', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas Dashboard', icon: AppIcons.insights),
            DashboardMenuItem(label: 'Ideathons', icon: AppIcons.ideathons),
            DashboardMenuItem(label: 'Judges Panel', icon: AppIcons.judges),
            DashboardMenuItem(label: 'Requests', icon: Icons.inbox_rounded),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.judge:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Scoring', icon: AppIcons.scoring),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.teamMember:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Problems', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas', icon: AppIcons.ideas),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.coordinator:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Team Registration', icon: AppIcons.teams),
            DashboardMenuItem(label: 'Payment Verification', icon: AppIcons.verification),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
    }
  }
}
