import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import '../../screens/common/dashboard_components.dart';
import 'dashboard_scrollable_body.dart';

/// Adaptive dashboard shell: drawer (mobile), collapsible rail (tablet), sidebar (desktop).
class ResponsiveDashboardLayout extends StatefulWidget {
  const ResponsiveDashboardLayout({
    super.key,
    required this.primaryMenus,
    required this.secondaryMenus,
    required this.selectedPrimaryIndex,
    required this.onPrimaryMenuSelected,
    required this.onLogout,
    required this.header,
    required this.body,
  });

  final List<DashboardMenuItem> primaryMenus;
  final List<DashboardMenuItem> secondaryMenus;
  final int selectedPrimaryIndex;
  final ValueChanged<int> onPrimaryMenuSelected;
  final VoidCallback onLogout;
  final Widget header;
  final Widget body;

  @override
  State<ResponsiveDashboardLayout> createState() => _ResponsiveDashboardLayoutState();
}

class _ResponsiveDashboardLayoutState extends State<ResponsiveDashboardLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _tabletRailExpanded = false;

  void _selectMenu(int index) {
    widget.onPrimaryMenuSelected(index);
    if (ResponsiveHelper.isMobile(context)) {
      Navigator.of(context).pop();
    }
  }

  void _handleLogout() {
    if (ResponsiveHelper.isMobile(context)) {
      Navigator.of(context).pop();
    }
    widget.onLogout();
  }

  Widget _navigationPanel({required bool compact, required bool inDrawer}) {
    return DashboardNavigationPanel(
      primaryMenus: widget.primaryMenus,
      secondaryMenus: widget.secondaryMenus,
      selectedPrimaryIndex: widget.selectedPrimaryIndex,
      onPrimaryMenuTap: _selectMenu,
      onLogout: _handleLogout,
      compact: compact,
      showBranding: !compact || inDrawer,
    );
  }

  Widget? _buildSidebar(BuildContext context, ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.mobile:
        return null;
      case ScreenSize.tablet:
        return _TabletSidebarRail(
          expanded: _tabletRailExpanded,
          onToggle: () => setState(() => _tabletRailExpanded = !_tabletRailExpanded),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: _navigationPanel(compact: !_tabletRailExpanded, inDrawer: false),
          ),
        );
      case ScreenSize.desktop:
      case ScreenSize.wide:
        return SidebarWidget(
          primaryMenus: widget.primaryMenus,
          secondaryMenus: widget.secondaryMenus,
          selectedPrimaryIndex: widget.selectedPrimaryIndex,
          onPrimaryMenuTap: widget.onPrimaryMenuSelected,
          onLogout: _handleLogout,
        );
    }
  }

  Widget _mainCard(BuildContext context, {VoidCallback? onOpenMenu}) {
    final innerPadding = ResponsiveHelper.dashboardInnerPadding(context);
    final radius = ResponsiveHelper.dashboardContentRadius(context);

    Widget header = widget.header;
    if (onOpenMenu != null) {
      header = _MobileMenuHeaderRow(onOpenMenu: onOpenMenu, child: header);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: innerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            header,
            SizedBox(height: dashboardHeaderBodyGap(context)),
            Expanded(
              child: DashboardBodySlot(child: widget.body),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.screenSizeOf(context);
    final outerPadding = ResponsiveHelper.dashboardOuterPadding(context);
    final gap = ResponsiveHelper.sidebarContentGap(context);
    final sidebar = _buildSidebar(context, screenSize);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3F5FB),
      drawer: screenSize == ScreenSize.mobile
          ? Drawer(
              width: 280,
              child: SafeArea(
                child: _navigationPanel(compact: false, inDrawer: true),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: outerPadding,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final main = _mainCard(
                context,
                onOpenMenu: screenSize == ScreenSize.mobile
                    ? () => _scaffoldKey.currentState?.openDrawer()
                    : null,
              );

              if (sidebar == null) {
                return SizedBox(height: constraints.maxHeight, child: main);
              }

              return SizedBox(
                height: constraints.maxHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    sidebar,
                    SizedBox(width: gap),
                    Expanded(child: main),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileMenuHeaderRow extends StatelessWidget {
  const _MobileMenuHeaderRow({
    required this.onOpenMenu,
    required this.child,
  });

  final VoidCallback onOpenMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton(
          onPressed: onOpenMenu,
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Open menu',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const SizedBox(width: 4),
        Expanded(child: child),
      ],
    );
  }
}

class _TabletSidebarRail extends StatelessWidget {
  const _TabletSidebarRail({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = expanded ? ResponsiveHelper.expandedSidebarWidth(context) : ResponsiveHelper.compactSidebarWidth;
    return SizedBox(
      width: width,
      child: Column(
        children: <Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: width,
              child: child,
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Icon(
                  expanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
