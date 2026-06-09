import 'package:flutter/material.dart';

import '../../core/responsive/responsive_helper.dart';
import '../../utils/leaderboard_role_config.dart';
import '../common/rich_tabs.dart';

class LeaderboardTabSection extends StatelessWidget {
  const LeaderboardTabSection({
    super.key,
    required this.visibleTabs,
    required this.tabChildren,
    this.height,
  });

  final List<LeaderboardShowcaseTab> visibleTabs;
  final List<Widget> tabChildren;

  /// When null, height adapts to viewport (mobile/tablet get shorter bodies).
  final double? height;

  static double _tabBodyHeight(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    if (ResponsiveHelper.isMobile(context)) {
      return (screenH * 0.42).clamp(280.0, 420.0);
    }
    if (ResponsiveHelper.isTablet(context)) {
      return (screenH * 0.48).clamp(340.0, 520.0);
    }
    return (screenH * 0.55).clamp(380.0, 620.0);
  }

  @override
  Widget build(BuildContext context) {
    if (visibleTabs.isEmpty || tabChildren.length != visibleTabs.length) {
      return const SizedBox.shrink();
    }

    final bodyHeight = height ?? _tabBodyHeight(context);

    return RichTabs(
      isScrollable: true,
      fitBodyHeight: true,
      bodyHeight: bodyHeight,
      spacingAfterBar: 12,
      tabs: visibleTabs
          .map(
            (t) => RichTabItem(
              switch (t) {
                LeaderboardShowcaseTab.teams => 'Teams',
                LeaderboardShowcaseTab.departments => 'Departments',
                LeaderboardShowcaseTab.mentors => 'Mentors',
                LeaderboardShowcaseTab.ideas => 'Ideas',
              },
            ),
          )
          .toList(growable: false),
      children: tabChildren,
    );
  }
}
