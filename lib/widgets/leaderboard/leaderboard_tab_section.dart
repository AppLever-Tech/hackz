import 'package:flutter/material.dart';

import '../../utils/leaderboard_role_config.dart';

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

    return DefaultTabController(
      length: visibleTabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF312E81),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF8B5CF6),
              indicatorWeight: 3,
              tabs: visibleTabs
                  .map(
                    (t) => Tab(
                      text: switch (t) {
                        LeaderboardShowcaseTab.teams => 'Teams',
                        LeaderboardShowcaseTab.departments => 'Departments',
                        LeaderboardShowcaseTab.mentors => 'Mentors',
                        LeaderboardShowcaseTab.ideas => 'Ideas',
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: TabBarView(
              children: tabChildren,
            ),
          ),
        ],
      ),
    );
  }
}
