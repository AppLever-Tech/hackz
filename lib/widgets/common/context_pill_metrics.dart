import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';

/// Shared sizing and typography for [ContextPill] and workspace navigation UI.
abstract final class ContextPillMetrics {
  ContextPillMetrics._();

  // --- Typography (same for compact and standard pills) ---
  static const double fontSize = 12;
  static const FontWeight fontWeight = FontWeight.w700;
  static const double letterSpacing = 0.15;
  static const double lineHeight = 1.2;

  // --- Icon ---
  static const double iconSize = 14;
  static const double iconLabelGap = 6;

  // --- Pill shape ---
  static const double height = 34;
  static const double borderRadiusValue = 10;
  static const double borderWidth = 1;
  static const double borderWidthHover = 1.4;

  static const double horizontalPadding = 10;
  static const double verticalPadding = 6;

  /// Slightly taller pill on non-compact layouts.
  static const double heightStandard = 38;
  static const double horizontalPaddingStandard = 12;
  static const double verticalPaddingStandard = 7;
  static const double borderRadiusStandard = 12;
  static const double iconSizeStandard = 15;
  static const double iconLabelGapStandard = 6;

  // --- Width caps (fit-content pills) ---
  static const double fitMaxWidthDefault = 280;
  static const double fitMaxWidthUserJudge = 220;

  static TextStyle labelStyle(Color color) => TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: lineHeight,
        color: color,
      );

  static double resolvedHeight({
    required BuildContext context,
    bool compact = true,
    double? override,
  }) {
    if (override != null) return override;
    if (compact) return height;
    return ResponsiveHelper.isMobile(context) ? 40 : heightStandard;
  }

  static double resolvedIconSize({bool compact = true}) => compact ? iconSize : iconSizeStandard;

  static double resolvedIconGap({bool compact = true}) => compact ? iconLabelGap : iconLabelGapStandard;

  static EdgeInsets resolvedPadding(BuildContext context, {bool compact = true}) {
    if (compact) {
      return const EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: ResponsiveHelper.isMobile(context) ? horizontalPaddingStandard + 1 : horizontalPaddingStandard,
      vertical: ResponsiveHelper.isMobile(context) ? 8 : verticalPaddingStandard,
    );
  }

  static BorderRadius resolvedBorderRadius({bool compact = true}) {
    return BorderRadius.circular(compact ? borderRadiusValue : borderRadiusStandard);
  }

  static double defaultFitMaxWidth({required bool compact, required bool isUserOrJudge}) {
    if (isUserOrJudge) return fitMaxWidthUserJudge;
    return compact ? fitMaxWidthDefault : 320;
  }
}
