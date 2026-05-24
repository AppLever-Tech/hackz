import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import 'context_pill_theme.dart';

/// Shared sizing and typography for [ContextPill] and workspace navigation UI.
abstract final class ContextPillMetrics {
  ContextPillMetrics._();

  // --- Workspace pill standard (student dashboard My Team Overview) ---
  static const double workspaceIconSize = 18;
  static const double workspaceFontSize = 12;
  static const FontWeight workspaceFontWeight = FontWeight.w700;
  static const double workspaceLetterSpacing = 0.15;
  static const double workspaceLineHeight = 1.2;
  static const double workspaceIconLabelGap = 6;
  static const double workspaceHeight = 34;
  /// Darker icon tint for workspace launch pills ([AppIcons] only).
  static const Color workspaceIconColor = Color(0xFF1E293B);

  // --- Compact defaults (match workspace standard) ---
  static const double fontSize = workspaceFontSize;
  static const FontWeight fontWeight = workspaceFontWeight;
  static const double letterSpacing = workspaceLetterSpacing;
  static const double lineHeight = workspaceLineHeight;
  static const double iconSize = workspaceIconSize;
  static const double iconLabelGap = workspaceIconLabelGap;
  static const double height = workspaceHeight;

  // --- Pill shape ---
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
  static const double iconSizeStandard = 18;
  static const double iconLabelGapStandard = 6;

  // --- Width caps (fit-content pills) ---
  static const double fitMaxWidthDefault = 280;
  static const double fitMaxWidthUserJudge = 220;

  static bool isWorkspaceSemantic(ContextPillSemantic semantic) =>
      semantic != ContextPillSemantic.generic;

  static Color iconColorFor({
    required ContextPillSemantic semantic,
    required Color labelColor,
  }) {
    if (isWorkspaceSemantic(semantic)) return workspaceIconColor;
    return labelColor;
  }

  static TextStyle labelStyle(Color color, {ContextPillSemantic? semantic}) {
    final bool workspace = semantic == null || isWorkspaceSemantic(semantic);
    return TextStyle(
      fontSize: workspace ? workspaceFontSize : fontSize,
      fontWeight: workspaceFontWeight,
      letterSpacing: workspaceLetterSpacing,
      height: workspaceLineHeight,
      color: color,
    );
  }

  static double resolvedHeight({
    required BuildContext context,
    bool compact = true,
    double? override,
  }) {
    if (override != null) return override;
    if (compact) return workspaceHeight;
    return ResponsiveHelper.isMobile(context) ? 40 : heightStandard;
  }

  static double resolvedIconSize({
    bool compact = true,
    ContextPillSemantic? semantic,
  }) {
    if (compact) {
      return workspaceIconSize;
    }
    return iconSizeStandard;
  }

  static double resolvedIconGap({bool compact = true}) =>
      compact ? workspaceIconLabelGap : iconLabelGapStandard;

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

  /// Inset for pills in clipped dashboard lists (hover scale, border, glow).
  static const EdgeInsets clippedListPadding = EdgeInsets.fromLTRB(8, 4, 6, 4);
}
