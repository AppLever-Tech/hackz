import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../responsive/responsive_helper.dart';

/// Entity semantics for contextual workspace navigation pills.
enum ContextPillSemantic {
  generic,
  user,
  team,
  idea,
  problem,
  payment,
  evaluation,
  judge,
}

/// Resolved metrics and colors for [ContextPill].
abstract final class ContextPillTheme {
  static ContextPillPalette paletteFor(ContextPillSemantic semantic) {
    return switch (semantic) {
      ContextPillSemantic.user => AppSemanticColors.contextUser,
      ContextPillSemantic.team => AppSemanticColors.contextTeam,
      ContextPillSemantic.idea => AppSemanticColors.contextIdea,
      ContextPillSemantic.problem => AppSemanticColors.contextProblem,
      ContextPillSemantic.payment => AppSemanticColors.contextPayment,
      ContextPillSemantic.evaluation => AppSemanticColors.contextEvaluation,
      ContextPillSemantic.judge => AppSemanticColors.contextUser,
      ContextPillSemantic.generic => AppSemanticColors.contextGeneric,
    };
  }

  static ContextPillSemantic semanticFromEntityLabel(String? label) {
    final String key = (label ?? '').trim().toLowerCase();
    return switch (key) {
      'user' || 'mentor' || 'student' || 'judge' || 'payer' => ContextPillSemantic.user,
      'team' => ContextPillSemantic.team,
      'idea' => ContextPillSemantic.idea,
      'problem' => ContextPillSemantic.problem,
      'payment' => ContextPillSemantic.payment,
      'evaluation' => ContextPillSemantic.evaluation,
      _ => ContextPillSemantic.generic,
    };
  }

  static String workspaceTooltipFor(ContextPillSemantic semantic) {
    return switch (semantic) {
      ContextPillSemantic.user => 'Open user in workspace',
      ContextPillSemantic.team => 'Open team in workspace',
      ContextPillSemantic.idea => 'Open idea in workspace',
      ContextPillSemantic.problem => 'Open problem in workspace',
      ContextPillSemantic.payment => 'Open payment in workspace',
      ContextPillSemantic.evaluation => 'Open evaluation in workspace',
      ContextPillSemantic.judge => 'Open judge in workspace',
      ContextPillSemantic.generic => 'Open in workspace',
    };
  }

  static EdgeInsets paddingFor(BuildContext context, {bool compact = false}) {
    if (compact) {
      return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
    }
    return EdgeInsets.symmetric(
      horizontal: ResponsiveHelper.isMobile(context) ? 12 : 11,
      vertical: ResponsiveHelper.isMobile(context) ? 8 : 6,
    );
  }

  static double minHeightFor(BuildContext context, {bool compact = false}) {
    if (compact) return ResponsiveHelper.isMobile(context) ? 32 : 28;
    return ResponsiveHelper.isMobile(context) ? 38 : 34;
  }

  static BorderRadius borderRadiusFor({bool compact = false}) {
    return BorderRadius.circular(compact ? 10 : 12);
  }
}
