import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../evaluations/services/evaluation_aggregation_service.dart';
import '../models/idea_model.dart';

/// Evaluation aggregate metrics for idea details (single source of truth).
class IdeaEvaluationResultsSection extends StatelessWidget {
  const IdeaEvaluationResultsSection({
    super.key,
    required this.idea,
    this.rank,
  });

  final IdeaModel idea;
  final int? rank;

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
        'Evaluation results will appear once judges complete scoring.',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.4),
      );
    }

    final String average = aggregate.averageScore!.toStringAsFixed(1);
    final String highest = aggregate.highestScore!.toStringAsFixed(1);
    final String lowest = aggregate.lowestScore!.toStringAsFixed(1);
    final String judges = '${aggregate.totalEvaluators}';
    final int? resolvedRank = rank ?? idea.evaluationRank;

    final List<DashboardMetricChipData> chips = <DashboardMetricChipData>[
      DashboardMetricChipData.single(
        label: 'Average',
        value: average,
        color: const Color(0xFF6A38FF),
        icon: Icons.analytics_outlined,
      ),
      DashboardMetricChipData.single(
        label: 'Highest',
        value: highest,
        color: const Color(0xFF059669),
        icon: Icons.trending_up_rounded,
      ),
      DashboardMetricChipData.single(
        label: 'Lowest',
        value: lowest,
        color: const Color(0xFFEA580C),
        icon: Icons.trending_down_rounded,
      ),
      DashboardMetricChipData.single(
        label: 'Judges',
        value: judges,
        color: const Color(0xFF0EA5E9),
        icon: Icons.gavel_outlined,
      ),
    ];

    if (resolvedRank != null && resolvedRank > 0) {
      chips.add(
        DashboardMetricChipData.single(
          label: 'Rank',
          value: '#$resolvedRank',
          color: const Color(0xFFD97706),
          icon: Icons.leaderboard_outlined,
        ),
      );
    }

    final bool compact = ResponsiveHelper.isMobile(context);
    return ResponsiveMetricGrid(
      spacing: compact ? 8 : 10,
      runSpacing: compact ? 8 : 10,
      chips: chips,
    );
  }
}
