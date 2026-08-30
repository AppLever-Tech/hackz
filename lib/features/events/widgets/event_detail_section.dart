import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';

/// Compact section card for Event Details modules.
class EventDetailSection extends StatelessWidget {
  const EventDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.titleSuffix,
    this.titleFontSize = 12,
    this.titleFontWeight = FontWeight.w800,
    this.titleColor = const Color(0xFF334155),
    this.collapsible = false,
    this.expanded = true,
    this.onToggle,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;
  /// Rendered immediately after the title (e.g. a count).
  final Widget? titleSuffix;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final Color titleColor;
  final bool collapsible;
  final bool expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bool showBody = !collapsible || expanded;
    final Widget header = Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16, color: titleColor),
          const SizedBox(width: 6),
        ],
        Flexible(
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
        if (titleSuffix != null) ...<Widget>[
          const SizedBox(width: 8),
          titleSuffix!,
        ],
        const Spacer(),
        if (collapsible) ...<Widget>[
          const SizedBox(width: 4),
          Icon(
            expanded ? AppIcons.expandLess : AppIcons.expandMore,
            size: 18,
            color: titleColor,
          ),
        ],
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.fromLTRB(14, 14, 14, showBody ? 18 : 14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          collapsible
              ? InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(8),
                  child: header,
                )
              : header,
          if (showBody) ...<Widget>[
            const SizedBox(height: 8),
            child,
          ],
        ],
      ),
    );
  }
}
