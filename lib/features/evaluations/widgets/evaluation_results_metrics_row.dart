import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
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
        MetricKpiSegment.count(metrics.shortlisted, 'Shortlisted'),
        MetricKpiSegment.count(metrics.rejected, 'Rejected'),
        MetricKpiSegment.count(metrics.pendingReview, 'Pending Review'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Evaluated',
          value: '${metrics.totalEvaluated}',
          color: const Color(0xFF6A38FF),
          icon: AppIcons.statusEvaluated,
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
        DashboardMetricChipData.single(
          label: 'Pending Review',
          value: '${metrics.pendingReview}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.statusUnderEvaluation,
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
