import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

/// Shared compact count chip: icon, label, and a stronger numeric value.
abstract final class CountPillStyle {
  CountPillStyle._();

  static const Color fill = Color(0xFFFCFDFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color iconColor = Color(0xFF57629A);
  static const Color labelColor = Color(0xFF64748B);
  static const Color countColor = Color(0xFF0F172A);

  static const double iconSize = 14;
  static const double iconGap = 4;
  static const double labelGap = 5;
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 5);

  static const TextStyle labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: labelColor,
    height: 1,
  );

  static const TextStyle countStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: countColor,
    height: 1,
  );
}

/// Icon + label + count pill used on department cards and other compact summaries.
class CountPill extends StatelessWidget {
  const CountPill({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    this.tooltip,
  });

  factory CountPill.teamMembers(int count) {
    return CountPill(
      icon: AppIcons.teamMember,
      label: 'Team Members',
      count: count,
    );
  }

  factory CountPill.judges(int count) {
    return CountPill(
      icon: AppIcons.judges,
      label: 'Judges',
      count: count,
    );
  }

  factory CountPill.coordinators(int count) {
    return CountPill(
      icon: AppIcons.coordinator,
      label: 'Coordinators',
      count: count,
    );
  }

  final IconData icon;
  final String label;
  final int count;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget pill = Container(
      padding: CountPillStyle.padding,
      decoration: BoxDecoration(
        color: CountPillStyle.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CountPillStyle.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: CountPillStyle.iconSize, color: CountPillStyle.iconColor),
          const SizedBox(width: CountPillStyle.iconGap),
          Text(label, style: CountPillStyle.labelStyle),
          const SizedBox(width: CountPillStyle.labelGap),
          Text('$count', style: CountPillStyle.countStyle),
        ],
      ),
    );

    final String message = (tooltip ?? label).trim();
    if (message.isEmpty) return pill;
    return Tooltip(message: message, child: pill);
  }
}
