import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

/// Shared floating create action for mobile list/management screens.
abstract final class MobileCreateFabStyles {
  MobileCreateFabStyles._();

  static const double size = 56;
  static const double borderRadius = 16;
  static const double iconSize = 28;
  static const double elevation = 8;
  static const Color backgroundColor = Color(0xFF6A38FF);
  static const Color foregroundColor = Colors.white;
  static const Color shadowColor = Color(0x406A38FF);
  static const EdgeInsets screenMargin = EdgeInsets.only(right: 16, bottom: 16);

  /// Bottom inset for scrollable lists so the last row clears the FAB.
  static const double listBottomPadding = 80;
}

/// Square rounded-corner FAB (WhatsApp/Slack style) for mobile create actions.
class MobileCreateFab extends StatelessWidget {
  const MobileCreateFab({
    super.key,
    required this.onPressed,
    this.icon = AppIcons.add,
    this.tooltip = 'Create',
    this.margin = MobileCreateFabStyles.screenMargin,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: margin.right,
      bottom: margin.bottom,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Tooltip(
          message: tooltip,
          child: Material(
            elevation: MobileCreateFabStyles.elevation,
            shadowColor: MobileCreateFabStyles.shadowColor,
            color: MobileCreateFabStyles.backgroundColor,
            borderRadius: BorderRadius.circular(MobileCreateFabStyles.borderRadius),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(MobileCreateFabStyles.borderRadius),
              child: SizedBox(
                width: MobileCreateFabStyles.size,
                height: MobileCreateFabStyles.size,
                child: Icon(
                  icon,
                  size: MobileCreateFabStyles.iconSize,
                  color: MobileCreateFabStyles.foregroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
