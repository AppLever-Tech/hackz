import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';

/// Reusable metric row for judge scoring / evaluation workspace screens.
class JudgeEvaluationMetricsRow extends StatelessWidget {
  const JudgeEvaluationMetricsRow({
    super.key,
    required this.pendingCount,
    required this.evaluatedCount,
    required this.averageScore,
    required this.completionPercent,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final int pendingCount;
  final int evaluatedCount;
  final double? averageScore;
  final double completionPercent;
  final double spacing;
  final double runSpacing;

  String get _averageScoreLabel => averageScore == null ? '—' : averageScore!.toStringAsFixed(1);

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(pendingCount, 'Pending'),
        MetricKpiSegment.count(evaluatedCount, 'Evaluated'),
        MetricKpiSegment(value: _averageScoreLabel, label: 'Avg Score'),
        MetricKpiSegment(value: '${completionPercent.round()}%', label: 'Complete'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Pending',
          value: '$pendingCount',
          subtitle: 'Awaiting you',
          color: const Color(0xFFEA580C),
          icon: Icons.pending_actions_rounded,
        ),
        DashboardMetricChipData.single(
          label: 'Evaluated',
          value: '$evaluatedCount',
          subtitle: 'Your submissions',
          color: const Color(0xFF16A34A),
          icon: Icons.task_alt_rounded,
        ),
        DashboardMetricChipData.single(
          label: 'Avg score',
          value: _averageScoreLabel,
          subtitle: 'Given by you',
          color: const Color(0xFF6366F1),
          icon: Icons.insights_rounded,
        ),
        DashboardMetricChipData.single(
          label: 'Completion',
          value: '${completionPercent.round()}%',
          subtitle: 'Of in-scope queue',
          color: const Color(0xFF0EA5E9),
          icon: Icons.pie_chart_outline_rounded,
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
