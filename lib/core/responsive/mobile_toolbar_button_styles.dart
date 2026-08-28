import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

/// Shared list-toolbar filled/outlined styles (Manage Department, Problems, Ideas, …).
abstract final class MobileToolbarButtonStyles {
  MobileToolbarButtonStyles._();

  static const double toolbarIconSize = 16;

  static const double compactHeight = 36;
  static const double standardHeight = 44;
  static const double compactHorizontalPadding = 10;
  static const double standardHorizontalPadding = 16;
  static const Color separatorColor = Color(0xFFD9E2F5);

  static ButtonStyle filled({bool compact = true}) => FilledButton.styleFrom(
        minimumSize: Size(0, compact ? compactHeight : standardHeight),
        padding: EdgeInsets.symmetric(horizontal: compact ? compactHorizontalPadding : standardHorizontalPadding),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  static ButtonStyle outlined({bool compact = true}) => OutlinedButton.styleFrom(
        minimumSize: Size(0, compact ? compactHeight : standardHeight),
        padding: EdgeInsets.symmetric(horizontal: compact ? compactHorizontalPadding : standardHorizontalPadding),
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: const Color(0xFF334155),
        backgroundColor: const Color(0xFFFCFDFF),
        side: const BorderSide(color: separatorColor, width: 1.2),
      );

  static Widget verticalSeparator({double height = compactHeight}) {
    return Container(
      width: 1,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: separatorColor,
    );
  }

  /// Compact filled toolbar action (Create User, Add Judge, Create Team, …).
  static Widget filledIcon({
    required VoidCallback onPressed,
    required String label,
    IconData icon = AppIcons.add,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: toolbarIconSize),
      label: Text(label),
      style: filled(compact: true),
    );
  }

  /// Compact outlined toolbar action (Import Users, Show Filters, …).
  static Widget outlinedIcon({
    required VoidCallback onPressed,
    required String label,
    IconData icon = AppIcons.attachments,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: toolbarIconSize),
      label: Text(label),
      style: outlined(compact: true),
    );
  }
}
