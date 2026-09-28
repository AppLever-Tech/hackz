import 'package:flutter/material.dart';

class AchievementBadgeWidget extends StatelessWidget {
  const AchievementBadgeWidget({
    super.key,
    required this.badgeId,
    this.compact = false,
  });

  final String badgeId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final _BadgeStyle badge = _styleFor(badgeId);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: badge.gradient),
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(color: badge.gradient.last.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(badge.icon, size: compact ? 14 : 16, color: Colors.white),
          SizedBox(width: compact ? 4 : 6),
          Text(
            badge.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  static _BadgeStyle _styleFor(String raw) {
    final id = raw.trim().toLowerCase();
    switch (id) {
      case 'gold':
        return const _BadgeStyle(
          label: 'Gold Tier',
          icon: Icons.emoji_events_rounded,
          gradient: <Color>[Color(0xFFD97706), Color(0xFFFBBF24)],
        );
      case 'silver':
        return const _BadgeStyle(
          label: 'Silver Tier',
          icon: Icons.workspace_premium_rounded,
          gradient: <Color>[Color(0xFF64748B), Color(0xFF94A3B8)],
        );
      case 'bronze':
        return const _BadgeStyle(
          label: 'Bronze Tier',
          icon: Icons.military_tech_rounded,
          gradient: <Color>[Color(0xFFB45309), Color(0xFFD97706)],
        );
      case 'rising':
        return const _BadgeStyle(
          label: 'Rising Star',
          icon: Icons.bolt_rounded,
          gradient: <Color>[Color(0xFF6366F1), Color(0xFFA855F7)],
        );
      default:
        return const _BadgeStyle(
          label: 'Contender',
          icon: Icons.auto_awesome_rounded,
          gradient: <Color>[Color(0xFF0EA5E9), Color(0xFF22D3EE)],
        );
    }
  }
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
}
