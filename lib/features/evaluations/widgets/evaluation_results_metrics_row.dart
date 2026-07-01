import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../services/evaluation_results_query_service.dart';

/// Reusable metric row for evaluation results screens.
class EvaluationResultsMetricsRow extends StatelessWidget {
  const EvaluationResultsMetricsRow({
    super.key,
    required this.metrics,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final EvaluationResultsMetrics metrics;
  final double spacing;
  final double runSpacing;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(metrics.totalEvaluated, 'Evaluated'),
        MetricKpiSegment.count(metrics.readyForShortlisting, 'Ready'),
        MetricKpiSegment.count(metrics.shortlisted, 'Shortlisted'),
        MetricKpiSegment.count(metrics.rejected, 'Rejected'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Evaluated',
          value: '${metrics.totalEvaluated}',
          color: const Color(0xFF6A38FF),
          icon: AppIcons.statusEvaluated,
        ),
        DashboardMetricChipData.single(
          label: 'Ready for Shortlisting',
          value: '${metrics.readyForShortlisting}',
          color: const Color(0xFF0D9488),
          icon: AppIcons.statusReadyForShortlisting,
        ),
        DashboardMetricChipData.single(
          label: 'Shortlisted',
          value: '${metrics.shortlisted}',
          color: const Color(0xFF059669),
          icon: AppIcons.statusShortlisted,
        ),
        DashboardMetricChipData.single(
          label: 'Rejected',
          value: '${metrics.rejected}',
          color: const Color(0xFFDC2626),
          icon: AppIcons.statusRejected,
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
