import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../features/idea/models/enums/idea_status.dart';
import '../../features/idea/services/idea_status_helpers.dart';

/// Shared compact pill metrics for mobile dashboard row cards (score, attachments, etc.).
abstract final class MobileRowCardPillMetrics {
  MobileRowCardPillMetrics._();

  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const double borderRadius = 8;
  static const double iconSize = 13;
  static const double fontSize = 12.5;
  static const FontWeight fontWeight = FontWeight.w700;
  static const double iconLabelGap = 5;
}

/// Compact icon + label pill for mobile row cards. Sizes to content — never stretches full width.
class MobileRowCardPill extends StatelessWidget {
  const MobileRowCardPill({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.onTap,
    this.tooltip,
    this.enabled = true,
  });

  factory MobileRowCardPill.evaluation({
    Key? key,
    required double score,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    final String display =
        score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);
    return MobileRowCardPill(
      key: key,
      icon: AppIcons.scoring,
      label: display,
      backgroundColor: const Color(0xFFFFF4E8),
      borderColor: const Color(0xFFFCD9A8),
      foregroundColor: const Color(0xFFB45309),
      onTap: onTap,
      tooltip: tooltip ?? 'View evaluation',
      enabled: onTap != null,
    );
  }

  factory MobileRowCardPill.attachments({
    Key? key,
    required int count,
    VoidCallback? onTap,
  }) {
    return MobileRowCardPill(
      key: key,
      icon: AppIcons.attachments,
      label: '$count',
      backgroundColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
      foregroundColor: const Color(0xFF334155),
      onTap: onTap,
      tooltip: count == 0 ? 'No attachments' : '$count attachment${count == 1 ? '' : 's'}',
      enabled: onTap != null,
    );
  }

  factory MobileRowCardPill.status({
    Key? key,
    required IdeaStatus status,
  }) {
    final Color color = IdeaStatusHelpers.color(status);
    return MobileRowCardPill(
      key: key,
      icon: IdeaStatusHelpers.icon(status),
      label: IdeaStatusHelpers.label(status),
      backgroundColor: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.28),
      foregroundColor: color,
      tooltip: IdeaStatusHelpers.label(status),
      enabled: false,
    );
  }

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Widget pill = Container(
      padding: MobileRowCardPillMetrics.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(MobileRowCardPillMetrics.borderRadius),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: MobileRowCardPillMetrics.iconSize, color: foregroundColor),
          const SizedBox(width: MobileRowCardPillMetrics.iconLabelGap),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: MobileRowCardPillMetrics.fontSize,
                fontWeight: MobileRowCardPillMetrics.fontWeight,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );

    final bool interactive = enabled && onTap != null;
    final Widget child = interactive
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(MobileRowCardPillMetrics.borderRadius),
            child: pill,
          )
        : pill;

    if (tooltip == null || tooltip!.trim().isEmpty) return child;
    return Tooltip(message: tooltip, child: child);
  }
}
