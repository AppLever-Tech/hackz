import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import 'judge_evaluation_metrics_row.dart';

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
    final bool compact = ResponsiveHelper.isMobile(context);
    return JudgeEvaluationMetricsRow(
      pendingCount: pendingCount,
      evaluatedCount: evaluatedCount,
      averageScore: averageScore,
      completionPercent: completionPercent,
      spacing: compact ? 8 : 10,
      runSpacing: compact ? 8 : 10,
    );
  }
}
