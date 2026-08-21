import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../services/faculty_teams_service.dart';

/// Reusable metric row for faculty team workspace screens.
class TeamMetricsRow extends StatelessWidget {
  const TeamMetricsRow({
    super.key,
    required this.teamCount,
    required this.totalStudents,
    required this.activeIdeas,
    this.maxTeams,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final int teamCount;
  final int totalStudents;
  final int activeIdeas;
  final int? maxTeams;
  final double spacing;
  final double runSpacing;

  int get _maxTeams => maxTeams ?? FacultyTeamsService.maxTeamsPerFaculty;

  int get _remainingSlots =>
      (_maxTeams - teamCount).clamp(0, _maxTeams).toInt();

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment(
          value: '$teamCount/$_maxTeams',
          label: 'Teams',
        ),
        MetricKpiSegment.count(totalStudents, 'Team Members'),
        MetricKpiSegment.count(activeIdeas, 'Ideas'),
        MetricKpiSegment.count(_remainingSlots, 'Slots'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.ratio(
          label: 'Total Teams',
          primary: '$teamCount',
          secondary: '$_maxTeams',
          subtitle: 'Teams created',
          color: const Color(0xFF6A38FF),
          icon: AppIcons.teams,
        ),
        DashboardMetricChipData.single(
          label: 'Team Members',
          value: '$totalStudents',
          color: const Color(0xFF0EA5E9),
          icon: AppIcons.student,
        ),
        DashboardMetricChipData.single(
          label: 'Active Ideas',
          value: '$activeIdeas',
          color: const Color(0xFFEA580C),
          icon: AppIcons.ideas,
        ),
        DashboardMetricChipData.single(
          label: 'Team Capacity',
          value: FacultyTeamsService.capacityMessage(teamCount, maxTeams: _maxTeams),
          color: const Color(0xFF16A34A),
          icon: AppIcons.verification,
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
