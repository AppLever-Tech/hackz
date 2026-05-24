import 'package:flutter/material.dart';

import '../../utils/leaderboard_showcase_service.dart';
import 'achievement_badge_widget.dart';
import 'podium_widget.dart';
import 'trend_indicator_widget.dart';

class LeaderboardHeroSection extends StatelessWidget {
  const LeaderboardHeroSection({
    super.key,
    required this.hero,
    required this.podium,
  });

  final LeaderboardHeroVm hero;
  final List<TeamShowcaseRow> podium;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
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
          Row(
            children: const <Widget>[
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
          Text(
            hero.spotlightTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(Icons.groups_rounded, size: 18, color: Colors.white.withOpacity(0.85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hero.subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.88), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hero.departmentLabel,
            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Innovation Score',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      hero.innovationScore.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              TrendIndicatorWidget(direction: hero.trend),
              AchievementBadgeWidget(badgeId: hero.achievementId),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Rank #${hero.rank}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          PodiumWidget(rows: podium.take(3).toList(growable: false)),
        ],
      ),
    );
  }
}
