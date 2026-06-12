import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../widgets/deptadmin/department_metric_card.dart';

/// Reusable metric row for manage-users screens.
class UserMetricsRow extends StatelessWidget {
  const UserMetricsRow({
    super.key,
    required this.faculty,
    required this.students,
    required this.coordinators,
    required this.pending,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final int faculty;
  final int students;
  final int coordinators;
  final int pending;
  final double spacing;
  final double runSpacing;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(faculty, 'Faculty'),
        MetricKpiSegment.count(students, 'Students'),
        MetricKpiSegment.count(coordinators, 'Coordinators'),
        MetricKpiSegment.count(pending, 'Pending'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DepartmentMetricCard(
          value: '$faculty',
          label: 'Faculty',
          icon: AppIcons.faculty,
          iconBgColor: const Color(0xFFEAF2FF),
          tooltip: 'Active faculty in this department.',
        ).toChipData(),
        DepartmentMetricCard(
          value: '$students',
          label: 'Students',
          icon: AppIcons.student,
          iconBgColor: const Color(0xFFF2EDFF),
          tooltip: 'Active students in this department.',
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
