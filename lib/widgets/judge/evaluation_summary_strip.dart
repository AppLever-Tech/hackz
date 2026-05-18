import 'package:flutter/material.dart';

import '../dashboard/dashboard_metric_chips.dart';

/// Compact horizontal summary metrics for the judge evaluation workspace.
class EvaluationSummaryStrip extends StatelessWidget {
  const EvaluationSummaryStrip({
    super.key,
    required this.pendingCount,
    required this.evaluatedCount,
    required this.averageScore,
    required this.completionPercent,
  });

  final int pendingCount;
  final int evaluatedCount;
  final double? averageScore;
  final double completionPercent;

  @override
  Widget build(BuildContext context) {
    return DashboardMetricChipGrid(
      chips: <DashboardMetricChipData>[
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
          value: averageScore == null ? '—' : averageScore!.toStringAsFixed(1),
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
      ],
    );
  }
}
