import 'package:flutter/material.dart';

/// Shared compact toolbar button styles for mobile list screens.
abstract final class MobileToolbarButtonStyles {
  MobileToolbarButtonStyles._();

  static const double compactHeight = 36;
  static const double standardHeight = 44;
  static const double compactHorizontalPadding = 10;
  static const double standardHorizontalPadding = 16;

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
        side: const BorderSide(color: Color(0xFFD9E2F5), width: 1.2),
      );
}
