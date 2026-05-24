import 'package:flutter/material.dart';

import '../../utils/leaderboard_ranking_engine.dart';
import '../common/context_pill.dart';
import '../common/context_pill_theme.dart';
import 'achievement_badge_widget.dart';
import 'trend_indicator_widget.dart';

/// Compact showcase row emphasizing rank + score (leaderboard-specific pattern).
class RankShowcaseCard extends StatelessWidget {
  const RankShowcaseCard({
    super.key,
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.scoreLabel,
    required this.scoreValue,
    required this.trend,
    required this.achievementId,
    this.onOpenTitleWorkspace,
    this.titleWorkspaceSemantic = ContextPillSemantic.idea,
    this.onOpenSubtitleWorkspace,
    this.subtitleWorkspaceSemantic = ContextPillSemantic.team,
  });

  final int rank;
  final String title;
  final String subtitle;
  final VoidCallback? onOpenTitleWorkspace;
  final ContextPillSemantic titleWorkspaceSemantic;
  final VoidCallback? onOpenSubtitleWorkspace;
  final ContextPillSemantic subtitleWorkspaceSemantic;
  final String scoreLabel;
  final String scoreValue;
  final TrendDirection trend;
  final String achievementId;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (rank) {
      1 => const Color(0xFF7C3AED),
      2 => const Color(0xFF2563EB),
      3 => const Color(0xFFF97316),
      _ => const Color(0xFF475569),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF0F172A).withValues(alpha: 0.04),
            const Color(0xFF6366F1).withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Column(
              children: <Widget>[
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 4),
                TrendIndicatorWidget(direction: trend, compact: true),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (onOpenTitleWorkspace != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ContextPill(
                      label: title,
                      semantic: titleWorkspaceSemantic,
                      onTap: onOpenTitleWorkspace!,
                    ),
                  )
                else
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                const SizedBox(height: 4),
                if (onOpenSubtitleWorkspace != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ContextPill(
                      label: subtitle,
                      semantic: subtitleWorkspaceSemantic,
                      onTap: onOpenSubtitleWorkspace!,
                      compact: true,
                    ),
                  )
                else
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                scoreValue,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              Text(
                scoreLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              AchievementBadgeWidget(badgeId: achievementId, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}
