import 'package:flutter/material.dart';

/// Compact highlight tile for Fast Rising / Most Innovative / Highest Evaluated.
class InnovationHighlightCard extends StatelessWidget {
  const InnovationHighlightCard({
    super.key,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.metricLabel,
    required this.metricValue,
    this.onTap,
  });

  final String tag;
  final String title;
  final String subtitle;
  final String metricLabel;
  final String metricValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
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
              if (subtitle.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                metricLabel,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10),
              ),
              Text(
                metricValue,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
