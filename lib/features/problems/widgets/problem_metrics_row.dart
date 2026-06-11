import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../services/problem_query_service.dart';

/// Reusable metric chip row for problem-domain screens.
///
/// Renders the four high-level KPIs derived from a [ProblemDashboardMetrics]
/// snapshot (total / my department / with ideas / without ideas) using the
/// shared [ResponsiveListMetrics] + [DashboardMetricChipData] primitives, so
/// list screens use a compact KPI strip on mobile and the grid on desktop.
class ProblemMetricsRow extends StatelessWidget {
  const ProblemMetricsRow({
    super.key,
    required this.metrics,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final ProblemDashboardMetrics metrics;
  final double spacing;
  final double runSpacing;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(metrics.total, 'Problems'),
        MetricKpiSegment.count(metrics.withIdeas, 'With Ideas'),
        MetricKpiSegment.count(metrics.withoutIdeas, 'Without Ideas'),
        MetricKpiSegment.count(metrics.myDepartment, 'My Dept'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Total Problems',
          value: '${metrics.total}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.problems,
        ),
        DashboardMetricChipData.single(
          label: 'My Department',
          value: '${metrics.myDepartment}',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.departments,
        ),
        DashboardMetricChipData.single(
          label: 'With Ideas',
          value: '${metrics.withIdeas}',
          color: const Color(0xFF059669),
          icon: AppIcons.ideas,
        ),
        DashboardMetricChipData.single(
          label: 'Without Ideas',
          value: '${metrics.withoutIdeas}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.submissions,
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
