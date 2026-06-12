import 'package:flutter/material.dart';

import '../services/leaderboard_ranking_engine.dart';
import '../services/leaderboard_showcase_service.dart';
import 'innovation_highlight_card.dart';

/// Highlights fastest-rising / top evaluated ideas from pre-ranked rows.
class RisingIdeasWidget extends StatelessWidget {
  const RisingIdeasWidget({
    super.key,
    required this.rows,
  });

  final List<IdeaShowcaseRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    IdeaShowcaseRow? highestEvaluated;
    IdeaShowcaseRow? topInnovation;
    for (final r in rows) {
      highestEvaluated =
          highestEvaluated == null || r.finalScore > highestEvaluated.finalScore ? r : highestEvaluated;
      topInnovation =
          topInnovation == null || r.innovationScore > topInnovation.innovationScore ? r : topInnovation;
    }
    IdeaShowcaseRow rising = rows.first;
    for (final r in rows) {
      if (r.trend == TrendDirection.up) {
        rising = r;
        break;
      }
    }

    final IdeaShowcaseRow? ti = topInnovation;
    final IdeaShowcaseRow? he = highestEvaluated;

    final chips = <Widget>[
      InnovationHighlightCard(
        tag: 'Fast rising',
        title: rising.title,
        metricLabel: 'Composite',
        metricValue: rising.finalScore.toStringAsFixed(1),
        trend: rising.trend,
      ),
      if (ti != null)
        InnovationHighlightCard(
          tag: 'Most innovative',
          title: ti.title,
          metricLabel: 'Innovation',
          metricValue: ti.innovationScore.toStringAsFixed(1),
          trend: ti.trend,
        ),
      if (he != null)
        InnovationHighlightCard(
          tag: 'Highest evaluated',
          title: he.title,
          metricLabel: 'Final score',
          metricValue: he.finalScore.toStringAsFixed(1),
          trend: he.trend,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Innovation highlights',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => chips[i],
          ),
        ),
      ],
    );
  }
}
