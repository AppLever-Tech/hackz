import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../features/dashboard/deptadmin/widgets/department_metric_card.dart';

/// Reusable metric row for manage-users screens.
class UserMetricsRow extends StatelessWidget {
  const UserMetricsRow({
    super.key,
    required this.teamMembers,
    required this.coordinators,
    required this.pending,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final int teamMembers;
  final int coordinators;
  final int pending;
  final double spacing;
  final double runSpacing;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(teamMembers, 'Team Members'),
        MetricKpiSegment.count(coordinators, 'Coordinators'),
        MetricKpiSegment.count(pending, 'Pending'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DepartmentMetricCard(
          value: '$teamMembers',
          label: 'Team Members',
          icon: AppIcons.teamMember,
          iconBgColor: const Color(0xFFF2EDFF),
          tooltip: 'Active team members in this department.',
        ).toChipData(),
        DepartmentMetricCard(
          value: '$coordinators',
          label: 'Coordinators',
          icon: AppIcons.coordinator,
          iconBgColor: const Color(0xFFE9FAF0),
          tooltip: 'Active coordinators in this department.',
        ).toChipData(),
        DepartmentMetricCard(
          value: '$pending',
          label: 'Pending Users',
          icon: AppIcons.pendingUsers,
          iconBgColor: const Color(0xFFFFF7E6),
          tooltip: 'Users awaiting department approval.',
        ).toChipData(),
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
