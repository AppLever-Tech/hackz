import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../idea/models/idea_model.dart';
import '../services/evaluation_aggregation_service.dart';

/// Premium evaluation summary metrics (Average, Highest, Lowest, Judges).
class EvaluationSummaryCards extends StatelessWidget {
  const EvaluationSummaryCards({super.key, required this.idea});

  final IdeaModel idea;

  @override
  Widget build(BuildContext context) {
    final IdeaEvaluationAggregate aggregate = idea.hasEvaluationAggregate
        ? EvaluationAggregationService.fromIdeaFields(
            averageScore: idea.averageScore,
            highestScore: idea.highestScore,
            lowestScore: idea.lowestScore,
            totalEvaluators: idea.totalEvaluators,
          )
        : const IdeaEvaluationAggregate.empty();

    if (!aggregate.hasScores) {
      return const Text(
        'Evaluation summary will appear once judges complete scoring.',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.4),
      );
    }

    final List<DashboardMetricChipData> chips = <DashboardMetricChipData>[
      DashboardMetricChipData.single(
        label: 'Average Score',
        value: aggregate.averageScore!.toStringAsFixed(1),
        color: const Color(0xFF6A38FF),
        icon: Icons.analytics_outlined,
      ),
      DashboardMetricChipData.single(
        label: 'Highest Score',
        value: aggregate.highestScore!.toStringAsFixed(1),
        color: const Color(0xFF059669),
        icon: Icons.trending_up_rounded,
      ),
      DashboardMetricChipData.single(
        label: 'Lowest Score',
        value: aggregate.lowestScore!.toStringAsFixed(1),
        color: const Color(0xFFEA580C),
        icon: Icons.trending_down_rounded,
      ),
      DashboardMetricChipData.single(
        label: 'Total Evaluators',
        value: '${aggregate.totalEvaluators}',
        color: const Color(0xFF0EA5E9),
        icon: Icons.gavel_outlined,
      ),
    ];

    if (ResponsiveHelper.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < chips.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 8),
            DashboardMetricChip(data: chips[i]),
          ],
        ],
      );
    }

    return ResponsiveMetricGrid(chips: chips);
  }
}
