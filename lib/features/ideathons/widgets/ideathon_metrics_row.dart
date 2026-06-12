import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../widgets/deptadmin/department_metric_card.dart';
import '../models/ideathon_status.dart';
import '../services/ideathon_query_service.dart';

/// Reusable metric row for ideathon list screens.
class IdeathonMetricsRow extends StatelessWidget {
  const IdeathonMetricsRow({
    super.key,
    required this.rows,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final List<IdeathonListRow> rows;
  final double spacing;
  final double runSpacing;

  int _countFor(IdeathonStatus status) =>
      rows.where((IdeathonListRow row) => row.ideathon.status == status).length;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(rows.length, 'Events'),
        MetricKpiSegment.count(_countFor(IdeathonStatus.inProgress), 'In Progress'),
        MetricKpiSegment.count(_countFor(IdeathonStatus.scheduled), 'Scheduled'),
        MetricKpiSegment.count(_countFor(IdeathonStatus.completed), 'Completed'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DepartmentMetricCard(
          value: '${rows.length}',
          label: 'Total Events',
          icon: AppIcons.ideathons,
          iconBgColor: const Color(0xFFF2EDFF),
          tooltip: 'Ideathon events in this department.',
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
