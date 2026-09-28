import 'package:flutter/material.dart';

import '../models/event_leaderboard_entry.dart';
import '../../leaderboard/widgets/leaderboard_hero_section.dart';
import '../../leaderboard/widgets/rank_showcase_card.dart';
import '../../leaderboard/widgets/rising_ideas_widget.dart';

/// Reusable Event Leaderboard: graphic ranking for one event.
///
/// UI label is **Leaderboard**. Ranked entries must already come from that
/// event's evaluation results.
class EventLeaderboardSection extends StatelessWidget {
  const EventLeaderboardSection({
    super.key,
    required this.entries,
    required this.onOpenIdea,
    required this.onOpenTeam,
    this.emptyMessage =
        'Leaderboard appears when evaluation results are complete for this event.',
  });

  final List<EventLeaderboardEntry> entries;
  final ValueChanged<EventLeaderboardEntry> onOpenIdea;
  final ValueChanged<EventLeaderboardEntry> onOpenTeam;
  final String emptyMessage;

  static const int _remainingCap = 10;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final List<EventLeaderboardEntry> ranked = List<EventLeaderboardEntry>.from(entries)
      ..sort((EventLeaderboardEntry a, EventLeaderboardEntry b) => a.rank.compareTo(b.rank));
    final EventLeaderboardEntry spotlight = ranked.first;
    final List<EventLeaderboardEntry> podium = ranked.take(3).toList(growable: false);
    final List<EventLeaderboardEntry> remaining =
        ranked.skip(3).take(_remainingCap).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        LeaderboardHeroSection(
          spotlight: spotlight,
          podium: podium,
          onOpenIdea: onOpenIdea,
          onOpenTeam: onOpenTeam,
        ),
        const SizedBox(height: 18),
        RisingIdeasWidget(rows: ranked, onOpenIdea: onOpenIdea),
        if (remaining.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          const Text(
            'Ranking',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...remaining.map(
            (EventLeaderboardEntry e) => RankShowcaseCard(
              entry: e,
              onOpenIdea: onOpenIdea,
              onOpenTeam: onOpenTeam,
            ),
          ),
        ],
      ],
    );
  }
}
