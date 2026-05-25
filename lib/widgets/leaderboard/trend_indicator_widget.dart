import 'package:flutter/material.dart';

import '../../utils/leaderboard_ranking_engine.dart';

class TrendIndicatorWidget extends StatelessWidget {
  const TrendIndicatorWidget({
    super.key,
    required this.direction,
    this.compact = false,
  });

  final TrendDirection direction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (direction) {
      TrendDirection.up => Icons.trending_up_rounded,
      TrendDirection.down => Icons.trending_down_rounded,
      TrendDirection.stable => Icons.trending_flat_rounded,
    };
    final Color color = switch (direction) {
      TrendDirection.up => const Color(0xFF0F766E),
      TrendDirection.down => const Color(0xFFB91C1C),
      TrendDirection.stable => const Color(0xFF64748B),
    };
    final double size = compact ? 16 : 20;
    return Tooltip(
      message: switch (direction) {
        TrendDirection.up => 'Upward momentum',
        TrendDirection.down => 'Cooling',
        TrendDirection.stable => 'Stable',
      },
      child: Icon(icon, size: size, color: color),
    );
  }
}
