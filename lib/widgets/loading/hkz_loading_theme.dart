import 'package:flutter/material.dart';

import '../../core/theme/auth_theme.dart';

/// Visual tokens for Hackz async loading overlays.
abstract final class HkzLoadingTheme {
  static const Color scrim = Color(0x6610143B);
  static const Color cardSurface = Color(0xF210143B);
  static const Color cardBorder = Color(0x33FFFFFF);
  static const Color titleColor = Colors.white;
  static const Color messageColor = Color(0xCCFFFFFF);
  static const Color successColor = Color(0xFF22C55E);
  static const Color errorColor = Color(0xFFF87171);

  static const LinearGradient accentGradient = LinearGradient(
    colors: <Color>[Color(0xFF6A38FF), Color(0xFFFF8C2B)],
  );

  static const LinearGradient arcGradient = LinearGradient(
    colors: <Color>[Color(0xFF6A38FF), Color(0xFF8B5CF6), Color(0xFFFF8C2B)],
  );

  static double cardWidth(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 380;
    if (w >= 600) return 340;
    return (w - 48).clamp(280, 320);
  }

  static TextStyle titleStyle(BuildContext context) => TextStyle(
        fontSize: MediaQuery.sizeOf(context).width >= 600 ? 17 : 16,
        fontWeight: FontWeight.w800,
        color: titleColor,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static const TextStyle messageStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: messageColor,
    height: 1.4,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardSurface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: cardBorder),
    boxShadow: const <BoxShadow>[
      BoxShadow(
        color: Color(0x406A38FF),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x26000000),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );

  static const Duration enterDuration = Duration(milliseconds: 220);
  static const Duration exitDuration = Duration(milliseconds: 180);
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Matches primary brand for retry actions.
  static Color get actionColor => AuthTheme.ink;
}
