import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';

/// Reusable metric row for team workspace screens.
class TeamMetricsRow extends StatelessWidget {
  const TeamMetricsRow({
    super.key,
    required this.teamCount,
    required this.totalTeamMembers,
    required this.activeIdeas,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final int teamCount;
  final int totalTeamMembers;
  final int activeIdeas;
  final double spacing;
  final double runSpacing;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(teamCount, 'Teams'),
        MetricKpiSegment.count(totalTeamMembers, 'Team Members'),
        MetricKpiSegment.count(activeIdeas, 'Ideas'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Teams',
          value: '$teamCount',
          color: const Color(0xFF6A38FF),
          icon: AppIcons.teams,
        ),
        DashboardMetricChipData.single(
          label: 'Team Members',
          value: '$totalTeamMembers',
          color: const Color(0xFF0EA5E9),
          icon: AppIcons.teamMember,
        ),
        DashboardMetricChipData.single(
          label: 'Active Ideas',
          value: '$activeIdeas',
          color: const Color(0xFFEA580C),
          icon: AppIcons.ideas,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveListMetrics(
      spacing: spacing,
      runSpacing: runSpacing,
      chips: _chips,
      stripSegments: _stripSegments,
    );
  }
}
