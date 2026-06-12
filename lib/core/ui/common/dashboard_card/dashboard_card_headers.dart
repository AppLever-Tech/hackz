import 'package:flutter/material.dart';

import 'dashboard_layout_tokens.dart';

/// Reusable header blocks for dashboard cards (no theme changes).
abstract final class DashboardCardHeaders {
  static List<Widget> sectionTitle({
    required String title,
    required String subtitle,
    Color subtitleColor = const Color(0xFF64748B),
  }) {
    return <Widget>[
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
      ),
      const SizedBox(height: DashboardLayoutTokens.titleSubtitleGap),
      Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
      const SizedBox(height: DashboardLayoutTokens.bodyTopGap),
    ];
  }

  static List<Widget> timedList({
    required Widget headerRow,
    required String subtitle,
    Color subtitleColor = const Color(0xFF64748B),
    double gapBeforeBody = DashboardLayoutTokens.bodyTopGap,
  }) {
    return <Widget>[
      headerRow,
      const SizedBox(height: DashboardLayoutTokens.titleSubtitleGap),
      Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
      SizedBox(height: gapBeforeBody),
    ];
  }
}

/// Icon circle + title + count chip header used on list preview cards.
class DashboardIconCountHeader extends StatelessWidget {
  const DashboardIconCountHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.count,
    this.iconBgColor = const Color(0xFFF2EDFF),
    this.iconColor = const Color(0xFF6A38FF),
  });

  final String title;
  final IconData icon;
  final int count;
  final Color iconBgColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF3552CC)),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
