import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../models/ideathon_status.dart';
import '../services/ideathon_query_service.dart';
import '../services/ideathon_status_helpers.dart';

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
        MetricKpiSegment.count(_countFor(IdeathonStatus.scheduled), 'Scheduled'),
        MetricKpiSegment.count(_countFor(IdeathonStatus.inProgress), 'In Progress'),
        MetricKpiSegment.count(_countFor(IdeathonStatus.completed), 'Completed'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Events',
          value: '${rows.length}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.ideathons,
          tooltip: 'Ideathon events in this department.',
        ),
        DashboardMetricChipData.single(
          label: 'Scheduled',
          value: '${_countFor(IdeathonStatus.scheduled)}',
          color: IdeathonStatusHelpers.color(IdeathonStatus.scheduled),
          icon: IdeathonStatusHelpers.icon(IdeathonStatus.scheduled),
        ),
        DashboardMetricChipData.single(
          label: 'In Progress',
          value: '${_countFor(IdeathonStatus.inProgress)}',
          color: IdeathonStatusHelpers.color(IdeathonStatus.inProgress),
          icon: IdeathonStatusHelpers.icon(IdeathonStatus.inProgress),
        ),
        DashboardMetricChipData.single(
          label: 'Completed',
          value: '${_countFor(IdeathonStatus.completed)}',
          color: IdeathonStatusHelpers.color(IdeathonStatus.completed),
          icon: IdeathonStatusHelpers.icon(IdeathonStatus.completed),
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
