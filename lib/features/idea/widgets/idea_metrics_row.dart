import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../services/idea_query_service.dart';

/// Reusable metric row for idea list/management screens.
class IdeaMetricsRow extends StatelessWidget {
  const IdeaMetricsRow({
    super.key,
    required this.metrics,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final IdeaDepartmentMetrics metrics;
  final double spacing;
  final double runSpacing;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(metrics.total, 'Ideas'),
        MetricKpiSegment.count(metrics.submitted, 'Submitted'),
        MetricKpiSegment.count(metrics.approved, 'Shortlisted'),
        MetricKpiSegment.count(metrics.evaluated, 'Evaluated'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Ideas',
          value: '${metrics.total}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.ideas,
          subtitle: metrics.pendingSubmission > 0 ? '${metrics.pendingSubmission} pending' : null,
        ),
        DashboardMetricChipData.single(
          label: 'Submitted',
          value: '${metrics.submitted}',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.submissions,
        ),
        DashboardMetricChipData.single(
          label: 'Shortlisted',
          value: '${metrics.approved}',
          color: const Color(0xFF059669),
          icon: AppIcons.statusShortlisted,
        ),
        DashboardMetricChipData.single(
          label: 'Evaluated',
          value: '${metrics.evaluated}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.scoring,
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
