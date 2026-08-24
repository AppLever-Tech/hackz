import 'package:flutter/material.dart';

import '../../../features/dashboard/chrome/dashboard_components.dart';

/// Compact section card for Event Details modules.
class EventDetailSection extends StatelessWidget {
  const EventDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.titleFontSize = 12,
    this.titleFontWeight = FontWeight.w800,
    this.titleColor = const Color(0xFF334155),
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: titleColor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: titleFontWeight,
                    color: titleColor,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
