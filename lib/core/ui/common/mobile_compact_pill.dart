import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';

/// Shared compact pill metrics for mobile filter chips, tags, and row meta.
abstract final class MobileCompactPillMetrics {
  MobileCompactPillMetrics._();

  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const EdgeInsets paddingWithDelete = EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4);
  static const double borderRadius = 18;
  static const double iconSize = 13;
  static const double deleteIconSize = 14;
  static const double fontSize = 11;
  static const FontWeight fontWeight = FontWeight.w700;
  static const double iconLabelGap = 4;

  static const Color selectedForeground = Color(0xFF2E43C6);
  static const Color selectedBackground = Color(0xFFE8ECFF);
  static const Color selectedBorder = Color(0xFF6A38FF);
  static const Color neutralForeground = Color(0xFF475569);
  static const Color neutralBackground = Color(0xFFF1F5F9);
  static const Color neutralBorder = Color(0xFFE2E8F0);
}

/// Compact pill for mobile filters, active filter tags, and inline row chips.
class MobileCompactPill extends StatelessWidget {
  const MobileCompactPill({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.onDeleted,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final Color fg = foregroundColor ??
        (selected ? MobileCompactPillMetrics.selectedForeground : MobileCompactPillMetrics.neutralForeground);
    final Color bg = backgroundColor ??
        (selected ? MobileCompactPillMetrics.selectedBackground : MobileCompactPillMetrics.neutralBackground);
    final Color border = borderColor ??
        (selected ? MobileCompactPillMetrics.selectedBorder : MobileCompactPillMetrics.neutralBorder);
    final bool interactive = onTap != null;
    final bool dismissible = onDeleted != null;

    final Widget content = Container(
      padding: dismissible ? MobileCompactPillMetrics.paddingWithDelete : MobileCompactPillMetrics.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MobileCompactPillMetrics.borderRadius),
        border: Border.all(color: border, width: selected ? 1.4 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: MobileCompactPillMetrics.iconSize, color: fg),
            const SizedBox(width: MobileCompactPillMetrics.iconLabelGap),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: MobileCompactPillMetrics.fontSize,
                fontWeight: MobileCompactPillMetrics.fontWeight,
                color: fg,
              ),
            ),
          ),
          if (dismissible) ...<Widget>[
            const SizedBox(width: 2),
            InkWell(
              onTap: onDeleted,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(AppIcons.remove, size: MobileCompactPillMetrics.deleteIconSize, color: fg),
              ),
            ),
          ],
        ],
      ),
    );

    if (!interactive) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MobileCompactPillMetrics.borderRadius),
        child: content,
      ),
    );
  }
}
