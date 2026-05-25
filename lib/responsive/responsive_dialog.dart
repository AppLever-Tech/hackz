import 'package:flutter/material.dart';

import 'responsive_helper.dart';

/// Preset dialog widths — resolved per breakpoint in [ResponsiveDialogConstraints].
enum DialogWidthPreset {
  compact,
  standard,
  wide,
  extraWide,
}

/// Breakpoint-aware dialog sizing (mobile fullscreen, tablet/desktop centered).
abstract final class ResponsiveDialogConstraints {
  static bool useFullscreen(BuildContext context) => ResponsiveHelper.isMobile(context);

  static EdgeInsets dialogInsets(BuildContext context) {
    if (useFullscreen(context)) return EdgeInsets.zero;
    if (ResponsiveHelper.isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 28);
    }
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 36);
  }

  static double maxWidth(
    BuildContext context, {
    DialogWidthPreset preset = DialogWidthPreset.standard,
    double? override,
  }) {
    if (override != null && !useFullscreen(context)) return override;
    if (useFullscreen(context)) return double.infinity;

    if (ResponsiveHelper.isTablet(context)) {
      return switch (preset) {
        DialogWidthPreset.compact => 560,
        DialogWidthPreset.standard => 680,
        DialogWidthPreset.wide => 780,
        DialogWidthPreset.extraWide => 900,
      };
    }

    return switch (preset) {
      DialogWidthPreset.compact => 480,
      DialogWidthPreset.standard => 620,
      DialogWidthPreset.wide => 760,
      DialogWidthPreset.extraWide => 900,
    };
  }

  static EdgeInsets contentPadding(BuildContext context) {
    if (useFullscreen(context)) {
      return const EdgeInsets.fromLTRB(16, 12, 16, 16);
    }
    if (ResponsiveHelper.isTablet(context)) {
      return const EdgeInsets.all(22);
    }
    return const EdgeInsets.all(20);
  }
}
