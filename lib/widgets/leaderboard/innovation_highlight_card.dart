import 'package:flutter/material.dart';

import '../../utils/leaderboard_ranking_engine.dart';
import 'trend_indicator_widget.dart';

/// Compact horizontal highlight tile for “most innovative / fastest rising”.
class InnovationHighlightCard extends StatelessWidget {
  const InnovationHighlightCard({
    super.key,
    required this.tag,
    required this.title,
    required this.metricLabel,
    required this.metricValue,
    required this.trend,
  });

  final String tag;
  final String title;
  final String metricLabel;
  final String metricValue;
  final TrendDirection trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0EA5E9), Color(0xFF6366F1)],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x332563EB), blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(metricLabel, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10)),
                  Text(
                    metricValue,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const Spacer(),
              TrendIndicatorWidget(direction: trend),
            ],
          ),
        ],
      ),
    );
  }
}
