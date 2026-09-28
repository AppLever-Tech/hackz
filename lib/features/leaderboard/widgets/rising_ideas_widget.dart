import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_breakpoints.dart';
import '../../events/models/event_leaderboard_entry.dart';
import 'innovation_highlight_card.dart';

/// Innovation Highlights derived only from existing event ranking scores.
class RisingIdeasWidget extends StatelessWidget {
  const RisingIdeasWidget({
    super.key,
    required this.rows,
    this.onOpenIdea,
  });

  final List<EventLeaderboardEntry> rows;
  final ValueChanged<EventLeaderboardEntry>? onOpenIdea;

  @override
  Widget build(BuildContext context) {
    final EventLeaderboardEntry? highest = EventLeaderboardHighlights.highestEvaluated(rows);
    final EventLeaderboardEntry? innovative = EventLeaderboardHighlights.mostInnovative(rows);
    if (highest == null && innovative == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Innovation Highlights',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stack = constraints.maxWidth < ResponsiveBreakpoints.mobile;
            final List<Widget> cards = <Widget>[
              if (innovative != null)
                InnovationHighlightCard(
                  tag: 'Most innovative',
                  title: innovative.displayIdeaTitle,
                  subtitle: innovative.displayTeamName,
                  metricLabel: 'Peak score',
                  metricValue: innovative.peakScoreLabel,
                  onTap: onOpenIdea == null ? null : () => onOpenIdea!(innovative),
                ),
              if (highest != null)
                InnovationHighlightCard(
                  tag: 'Highest evaluated',
                  title: highest.displayIdeaTitle,
                  subtitle: highest.displayTeamName,
                  metricLabel: 'Score',
                  metricValue: highest.overallScoreLabel,
                  onTap: onOpenIdea == null ? null : () => onOpenIdea!(highest),
                ),
            ];
            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < cards.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 10),
                    cards[i],
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (int i = 0; i < cards.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
