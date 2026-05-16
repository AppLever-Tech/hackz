import 'package:flutter/material.dart';

import '../../utils/leaderboard_role_config.dart';
import '../common/rich_tabs.dart';

class LeaderboardTabSection extends StatelessWidget {
  const LeaderboardTabSection({
    super.key,
    required this.visibleTabs,
    required this.tabChildren,
    this.height = 520,
  });

  final List<LeaderboardShowcaseTab> visibleTabs;
  final List<Widget> tabChildren;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (visibleTabs.isEmpty || tabChildren.length != visibleTabs.length) {
      return const SizedBox.shrink();
    }

    return RichTabs(
      isScrollable: true,
      fitBodyHeight: true,
      bodyHeight: height,
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
