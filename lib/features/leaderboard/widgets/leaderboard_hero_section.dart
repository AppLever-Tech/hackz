import 'package:flutter/material.dart';

import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../events/models/event_leaderboard_entry.dart';
import 'achievement_badge_widget.dart';
import 'podium_widget.dart';

class LeaderboardHeroSection extends StatelessWidget {
  const LeaderboardHeroSection({
    super.key,
    required this.spotlight,
    required this.podium,
    this.onOpenIdea,
    this.onOpenTeam,
  });

  final EventLeaderboardEntry spotlight;
  final List<EventLeaderboardEntry> podium;
  final ValueChanged<EventLeaderboardEntry>? onOpenIdea;
  final ValueChanged<EventLeaderboardEntry>? onOpenTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1E1B4B),
            Color(0xFF312E81),
            Color(0xFF4C1D95),
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x55312467), blurRadius: 28, offset: Offset(0, 18)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.auto_graph_rounded, color: Color(0xFFE9D5FF)),
              SizedBox(width: 8),
              Text(
                'Innovation Spotlight',
                style: TextStyle(
                  color: Color(0xFFE9D5FF),
                  fontSize: 13,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ContextPill(
                label: spotlight.displayIdeaTitle,
                semantic: ContextPillSemantic.idea,
                onTap: () => onOpenIdea?.call(spotlight),
                enabled: onOpenIdea != null,
                compact: true,
                fitContent: true,
              ),
              ContextPill(
                label: spotlight.displayTeamName,
                semantic: ContextPillSemantic.team,
                onTap: () => onOpenTeam?.call(spotlight),
                enabled: onOpenTeam != null && spotlight.teamId.trim().isNotEmpty,
                compact: true,
                fitContent: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Score',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      spotlight.overallScoreLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              AchievementBadgeWidget(
                badgeId: switch (spotlight.rank) {
                  1 => 'gold',
                  2 => 'silver',
                  3 => 'bronze',
                  _ => 'contender',
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Rank #${spotlight.rank}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PodiumWidget(
            rows: podium.take(3).toList(growable: false),
            onOpenIdea: onOpenIdea,
            onOpenTeam: onOpenTeam,
          ),
        ],
      ),
    );
  }
}
