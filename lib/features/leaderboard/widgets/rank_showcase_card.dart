import 'package:flutter/material.dart';

import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../events/models/event_leaderboard_entry.dart';

/// Compact remaining-rank row: idea, team, overall score.
class RankShowcaseCard extends StatelessWidget {
  const RankShowcaseCard({
    super.key,
    required this.entry,
    this.onOpenIdea,
    this.onOpenTeam,
  });

  final EventLeaderboardEntry entry;
  final ValueChanged<EventLeaderboardEntry>? onOpenIdea;
  final ValueChanged<EventLeaderboardEntry>? onOpenTeam;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (entry.rank) {
      1 => const Color(0xFF7C3AED),
      2 => const Color(0xFF2563EB),
      3 => const Color(0xFFF97316),
      _ => const Color(0xFF475569),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF0F172A).withValues(alpha: 0.04),
            const Color(0xFF6366F1).withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget pills = Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ContextPill(
                label: entry.displayIdeaTitle,
                semantic: ContextPillSemantic.idea,
                onTap: () => onOpenIdea?.call(entry),
                enabled: onOpenIdea != null,
                compact: true,
                fitContent: true,
              ),
              ContextPill(
                label: entry.displayTeamName,
                semantic: ContextPillSemantic.team,
                onTap: () => onOpenTeam?.call(entry),
                enabled: onOpenTeam != null && entry.teamId.trim().isNotEmpty,
                compact: true,
                fitContent: true,
              ),
            ],
          );
          final Widget score = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                entry.overallScoreLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              const Text(
                'Score',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          );
          final Widget rankLabel = SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: accent,
              ),
            ),
          );
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    rankLabel,
                    const Spacer(),
                    score,
                  ],
                ),
                const SizedBox(height: 8),
                pills,
              ],
            );
          }
          return Row(
            children: <Widget>[
              rankLabel,
              Expanded(child: pills),
              const SizedBox(width: 8),
              score,
            ],
          );
        },
      ),
    );
  }
}
