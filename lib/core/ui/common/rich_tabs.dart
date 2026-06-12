import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';

/// Label for a [RichTabBar] / [RichTabs] segment.
class RichTabItem {
  const RichTabItem(this.label, {this.count, this.prominentCount = false});

  final String label;
  final int? count;

  /// Larger, bolder count text (e.g. coordinator payment verification tabs).
  final bool prominentCount;
}

/// Pill-style tab bar (scoring workspace). Requires an external [TabController].
class RichTabBar extends StatelessWidget {
  const RichTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.isScrollable = false,
  }) : assert(tabs.length > 0);

  final TabController controller;
  final List<RichTabItem> tabs;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final bool scrollable = isScrollable || ResponsiveHelper.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        isScrollable: scrollable,
        tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: const Color(0xFF64748B),
        tabs: tabs.map((RichTabItem tab) => _buildTab(tab, scrollable: scrollable)).toList(growable: false),
      ),
    );
  }

  Widget _buildTab(RichTabItem item, {required bool scrollable}) {
    if (item.count == null) {
      return Tab(
        child: Text(
          item.label,
          maxLines: 1,
          overflow: scrollable ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
      );
    }

    final TextStyle countStyle = TextStyle(
      fontSize: item.prominentCount ? 14 : 11,
      fontWeight: item.prominentCount ? FontWeight.w900 : FontWeight.w700,
      color: item.prominentCount ? const Color(0xFF334155) : const Color(0xFF94A3B8),
    );

    if (scrollable) {
      return Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(item.label),
            const SizedBox(width: 4),
            Text('(${item.count})', style: countStyle),
          ],
        ),
      );
    }

    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Flexible(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Text('(${item.count})', style: countStyle),
        ],
      ),
    );
  }
}

/// [RichTabBar] plus [TabBarView] with managed [TabController].
class RichTabs extends StatefulWidget {
  const RichTabs({
    super.key,
    required this.tabs,
    required this.children,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.isScrollable = false,
    this.spacingAfterBar = 12,
    this.fitBodyHeight = false,
    this.bodyHeight = 400,
  }) : assert(tabs.length > 0),
       assert(children.length == tabs.length);

  final List<RichTabItem> tabs;
  final List<Widget> children;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final bool isScrollable;
  final double spacingAfterBar;

  /// When true, body is a fixed [SizedBox] instead of [Expanded] (e.g. leaderboard).
  final bool fitBodyHeight;
  final double bodyHeight;

  @override
  State<RichTabs> createState() => _RichTabsState();
}

class _RichTabsState extends State<RichTabs> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    final maxIndex = widget.tabs.length - 1;
    _controller = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, maxIndex),
    );
    _controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_controller.indexIsChanging) {
      widget.onIndexChanged?.call(_controller.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = TabBarView(
      controller: _controller,
      children: widget.children,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RichTabBar(controller: _controller, tabs: widget.tabs, isScrollable: widget.isScrollable),
        SizedBox(height: widget.spacingAfterBar),
        if (widget.fitBodyHeight)
          SizedBox(height: widget.bodyHeight, child: body)
        else
          Expanded(child: body),
      ],
    );
  }
}
