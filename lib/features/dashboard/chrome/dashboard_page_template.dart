import 'package:flutter/material.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../core/firebase/tenant_firebase.dart';
import '../../../features/docs/data/docs_registry.dart';
import '../../../features/domain/domain.dart';
import '../../../features/user/models/enums/user_role.dart';
import '../../../features/user/models/user_model.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_dashboard_layout.dart';
import '../../../core/ui/common/page_header_context_pill.dart';
import '../../../features/auth/screens/landing_screen.dart';
import 'package:hackz/core/workspace/workspace_controller.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'dashboard_chrome_controller.dart';
import 'dashboard_chrome_scope.dart';
import 'dashboard_components.dart';
import 'dashboard_session_scope.dart';
import 'tenant_business_caches.dart';

class DashboardPageTemplate extends StatefulWidget {
  const DashboardPageTemplate({
    super.key,
    required this.user,
    required this.bodyBuilder,
    this.primaryMenusOverride,
    this.initialPrimaryMenuIndex = 0,
  });

  final UserModel user;
  final Widget Function(
    BuildContext context,
    int refreshToken,
    int selectedMenuIndex,
  ) bodyBuilder;

  /// When set, replaces the role-default primary navigation items.
  final List<DashboardMenuItem>? primaryMenusOverride;

  final int initialPrimaryMenuIndex;

  @override
  State<DashboardPageTemplate> createState() => _DashboardPageTemplateState();
}

class _DashboardPageTemplateState extends State<DashboardPageTemplate> {
  int _refreshToken = 0;
  late int _selectedPrimaryMenuIndex;
  final DashboardChromeController _chromeController = DashboardChromeController();

  @override
  void initState() {
    super.initState();
    _selectedPrimaryMenuIndex = widget.initialPrimaryMenuIndex;
  }

  @override
  void dispose() {
    _chromeController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    WorkspaceController.instance.close();
    _chromeController.clearOverlay();
    TenantBusinessCaches.clear();
    await TenantFirebase.releaseSession();
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
    final bool isDashboardTab = _selectedPrimaryMenuIndex == 0 &&
        primaryMenus.isNotEmpty &&
        primaryMenus.first.label == 'Dashboard';

    return DashboardSessionScope(
      user: widget.user,
      onLogout: () => _logout(context),
      child: DashboardChromeScope(
        controller: _chromeController,
        child: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            _chromeController,
            HackzFirebase.tenantGeneration,
          ]),
          builder: (BuildContext context, Widget? child) {
            _chromeController.bindPrimaryMenuNavigator(_selectPrimaryMenu);
            return ResponsiveDashboardLayout(
            primaryMenus: primaryMenus,
            secondaryMenus: menuConfig.secondaryMenus,
            selectedPrimaryIndex: _selectedPrimaryMenuIndex,
            onPrimaryMenuSelected: _selectPrimaryMenu,
            header: DashboardPageHeader(
              title: isDashboardTab ? 'Dashboard' : selectedMenuTitle,
              titleIcon: selectedMenuIcon,
              contextPills: _headerPills(),
              user: widget.user,
              onLogout: () => _logout(context),
              onUserTap: () => WorkspaceNavigator.openUser(
                context,
                widget.user.userId,
                actor: widget.user,
              ),
              helpPageId: isDashboardTab
                  ? null
                  : DocsRegistry.helpPageForContext(selectedMenuTitle),
              titleActions: _combinedTitleActions(
                context,
                role: role,
                selectedMenuTitle: selectedMenuTitle,
              ),
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

  List<PageHeaderContextItem> _headerPills() {
    return List<PageHeaderContextItem>.from(_chromeController.headerContextPills);
  }

  Widget? _combinedTitleActions(
    BuildContext context, {
    required UserRole role,
    required String selectedMenuTitle,
  }) {
    return _titleActionsFor(
      context,
      role: role,
      selectedMenuTitle: selectedMenuTitle,
    );
  }

  void _selectPrimaryMenu(int index) {
    if (index != _selectedPrimaryMenuIndex) {
      WorkspaceController.instance.close();
      _chromeController.clearOverlay();
      _chromeController.setHeaderContextPills(const <PageHeaderContextItem>[]);
    }
    setState(() => _selectedPrimaryMenuIndex = index);
  }

  Widget? _titleActionsFor(
    BuildContext context, {
    required UserRole role,
    required String selectedMenuTitle,
  }) {
    if (selectedMenuTitle != 'Problem Statements') return null;
    if (role == UserRole.orgAdmin || role == UserRole.collegeAdmin) {
      return DomainsHeaderAction(
        onPressed: () => showCollegeDomainManagementDialog(
          context: context,
          orgId: widget.user.orgId,
        ),
      );
    }
    if (role == UserRole.departmentAdmin) {
      return DomainsHeaderAction(
        onPressed: () => showDeptDomainManagementDialog(
          context: context,
          orgId: widget.user.orgId,
          departmentCode: widget.user.departmentCode,
          departmentName: widget.user.department,
        ),
      );
    }
    return null;
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
            DashboardMenuItem(label: 'Organisations', icon: AppIcons.organizations),
            DashboardMenuItem(label: 'Tenants', icon: AppIcons.verification),
            DashboardMenuItem(label: 'Hackz Org Admins', icon: AppIcons.helpSupport),
            DashboardMenuItem(label: 'App Metadata', icon: AppIcons.info),
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
            DashboardMenuItem(label: 'Events', icon: AppIcons.event),
            DashboardMenuItem(label: 'Org Settings', icon: AppIcons.orgSettings),
            DashboardMenuItem(label: 'AI Analysis', icon: Icons.psychology_outlined),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.departmentAdmin:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'People & Teams', icon: AppIcons.users),
            DashboardMenuItem(label: 'Problem Statements', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas Dashboard', icon: AppIcons.insights),
            DashboardMenuItem(label: 'Events', icon: AppIcons.event),
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
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
      case UserRole.orgAdmin:
        return const _RoleMenuConfig(
          primaryMenus: <DashboardMenuItem>[
            DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
            DashboardMenuItem(label: 'Manage College', icon: AppIcons.organizations),
            DashboardMenuItem(label: 'Problem Statements', icon: AppIcons.problems),
            DashboardMenuItem(label: 'Ideas Dashboard', icon: AppIcons.insights),
            DashboardMenuItem(label: 'Events', icon: AppIcons.event),
            DashboardMenuItem(label: 'Payment Verification', icon: AppIcons.verification),
            DashboardMenuItem(label: 'AI Analysis', icon: Icons.psychology_outlined),
          ],
          secondaryMenus: <DashboardMenuItem>[],
        );
    }
  }
}
