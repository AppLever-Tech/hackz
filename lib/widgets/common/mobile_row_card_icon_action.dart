import 'package:flutter/material.dart';

/// Shared metrics for compact icon action buttons on mobile dashboard row cards.
abstract final class MobileRowCardIconActionMetrics {
  MobileRowCardIconActionMetrics._();

  static const double size = 32;
  static const double iconSize = 16;
  static const double borderRadius = 10;
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color foregroundColor = Color(0xFF475569);
  static const Color dangerForegroundColor = Color(0xFFB91C1C);
  static const double gap = 6;
}

/// Compact tappable icon button for mobile list row cards (ideas, problems, etc.).
class MobileRowCardIconAction extends StatelessWidget {
  const MobileRowCardIconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.foregroundColor,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final Color color = foregroundColor ?? MobileRowCardIconActionMetrics.foregroundColor;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MobileRowCardIconActionMetrics.borderRadius),
        child: Container(
          width: MobileRowCardIconActionMetrics.size,
          height: MobileRowCardIconActionMetrics.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MobileRowCardIconActionMetrics.backgroundColor,
            borderRadius: BorderRadius.circular(MobileRowCardIconActionMetrics.borderRadius),
            border: Border.all(color: MobileRowCardIconActionMetrics.borderColor),
          ),
          child: Icon(icon, size: MobileRowCardIconActionMetrics.iconSize, color: color),
        ),
      ),
    );
  }
}

/// Inserts [MobileRowCardIconActionMetrics.gap] between icon action widgets.
List<Widget> spacedMobileRowCardIconActions(
  List<Widget> actions, {
  double gap = MobileRowCardIconActionMetrics.gap,
}) {
  if (actions.isEmpty) return actions;
  final List<Widget> spaced = <Widget>[actions.first];
  for (var i = 1; i < actions.length; i++) {
    spaced.add(SizedBox(width: gap));
    spaced.add(actions[i]);
  }
  return spaced;
}
