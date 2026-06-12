import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'responsive_helper.dart';
import '../../../screens/common/dashboard_components.dart';
import 'dashboard_scrollable_body.dart';

/// Adaptive dashboard shell shared by every role.
///
/// Layout per breakpoint:
///  * mobile  → hidden behind a [Drawer], toggled by the leading menu icon.
///  * tablet  → collapsible side rail. Collapsed by default.
///  * desktop → collapsible side rail. Collapsed by default.
///  * wide    → collapsible side rail. Expanded by default.
///
/// The rail uses [DashboardNavigationPanel] in `compact: true` mode when
/// collapsed and `compact: false` when expanded, so the visual treatment is
/// identical to the existing tablet rail (no new decoration helpers).
///
/// State: a single `bool? _railOverride` tracks the user's explicit choice.
/// When `null`, the effective expanded state follows the breakpoint default
/// — meaning resizing the browser without ever toggling re-applies the
/// breakpoint default. After the first toggle, the user's choice is sticky
/// for the remainder of the session.
class ResponsiveDashboardLayout extends StatefulWidget {
  const ResponsiveDashboardLayout({
    super.key,
    required this.primaryMenus,
    required this.secondaryMenus,
    required this.selectedPrimaryIndex,
    required this.onPrimaryMenuSelected,
    required this.header,
    required this.body,
    this.panelOverlay,
  });

  final List<DashboardMenuItem> primaryMenus;
  final List<DashboardMenuItem> secondaryMenus;
  final int selectedPrimaryIndex;
  final ValueChanged<int> onPrimaryMenuSelected;
  final Widget header;
  final Widget body;

  /// Covers the entire main panel (header + body), e.g. problem statement details.
  final Widget? panelOverlay;

  @override
  State<ResponsiveDashboardLayout> createState() => _ResponsiveDashboardLayoutState();
}

class _ResponsiveDashboardLayoutState extends State<ResponsiveDashboardLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// User's explicit collapsed/expanded choice. `null` means "follow the
  /// breakpoint default". Set by [_toggleRail].
  bool? _railOverride;

  /// Default expanded state for a given screen size. Wide screens default to
  /// expanded; everything narrower defaults to collapsed (mobile is unused —
  /// it routes through the drawer).
  bool _defaultExpandedFor(ScreenSize size) => size == ScreenSize.wide;

  bool _isExpanded(ScreenSize size) =>
      _railOverride ?? _defaultExpandedFor(size);

  void _toggleRail(ScreenSize size) {
    setState(() {
      _railOverride = !_isExpanded(size);
    });
  }

  void _selectMenu(int index) {
    widget.onPrimaryMenuSelected(index);
    if (ResponsiveHelper.isMobile(context)) {
      Navigator.of(context).pop();
    }
  }

  Widget _navigationPanel({
    required bool compact,
    required bool inDrawer,
    VoidCallback? onToggleCollapse,
  }) {
    return DashboardNavigationPanel(
      primaryMenus: widget.primaryMenus,
      secondaryMenus: widget.secondaryMenus,
      selectedPrimaryIndex: widget.selectedPrimaryIndex,
      onPrimaryMenuTap: _selectMenu,
      compact: compact,
      // Always show the brand block — on the rail it carries the collapse
      // toggle even when compact; in the drawer it's the standard header.
      showBranding: true,
      onToggleCollapse: onToggleCollapse,
    );
  }

  Widget? _buildSidebar(BuildContext context, ScreenSize screenSize) {
    if (screenSize == ScreenSize.mobile) return null;
    final bool expanded = _isExpanded(screenSize);
    return _CollapsibleSidebarRail(
      expanded: expanded,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: _navigationPanel(
          compact: !expanded,
          inDrawer: false,
          onToggleCollapse: () => _toggleRail(screenSize),
        ),
      ),
    );
  }

  Widget _mainCard(BuildContext context, {VoidCallback? onOpenMenu}) {
    final innerPadding = ResponsiveHelper.dashboardInnerPadding(context);
    final radius = ResponsiveHelper.dashboardContentRadius(context);

    Widget header = widget.header;
    if (onOpenMenu != null) {
      header = _MobileMenuHeaderRow(onOpenMenu: onOpenMenu, child: header);
    }

    final Widget panel = Container(
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

    final Widget? overlay = widget.panelOverlay;
    if (overlay == null) {
      return panel;
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        panel,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Material(
              color: Colors.white,
              child: Padding(
                padding: innerPadding,
                child: overlay,
              ),
            ),
          ),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: onOpenMenu,
          icon: const Icon(AppIcons.menu),
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

/// Tablet/desktop/wide rail. Animates between
/// [ResponsiveHelper.compactSidebarWidth] and
/// [ResponsiveHelper.expandedSidebarWidth] using a 200 ms cubic curve.
///
/// The collapse toggle now lives inside [DashboardNavigationPanel]'s brand
/// row, so this widget is just an animating width container around the
/// navigation panel.
class _CollapsibleSidebarRail extends StatelessWidget {
  const _CollapsibleSidebarRail({
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double width = expanded
        ? ResponsiveHelper.expandedSidebarWidth(context)
        : ResponsiveHelper.compactSidebarWidth;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: SizedBox(width: width, child: child),
    );
  }
}
