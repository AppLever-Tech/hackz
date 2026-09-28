import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

export 'responsive_breakpoints.dart' show ResponsiveBreakpoints, ScreenSize;

/// Central responsive queries and dashboard spacing tokens.
abstract final class ResponsiveHelper {
  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static ScreenSize screenSizeOf(BuildContext context) {
    final width = widthOf(context);
    if (width < ResponsiveBreakpoints.mobile) return ScreenSize.mobile;
    if (width < ResponsiveBreakpoints.tablet) return ScreenSize.tablet;
    if (width < ResponsiveBreakpoints.wide) return ScreenSize.desktop;
    return ScreenSize.wide;
  }

  static bool isMobile(BuildContext context) => screenSizeOf(context) == ScreenSize.mobile;

  static bool isTablet(BuildContext context) => screenSizeOf(context) == ScreenSize.tablet;

  static bool isDesktopOrWider(BuildContext context) {
    final size = screenSizeOf(context);
    return size == ScreenSize.desktop || size == ScreenSize.wide;
  }

  static bool isWide(BuildContext context) => screenSizeOf(context) == ScreenSize.wide;

  /// Compact auth landing for phone only; tablet+ uses premium web landing.
  static bool useCompactLanding(BuildContext context) => isMobile(context);

  /// Outer padding around the dashboard shell (SafeArea child).
  static EdgeInsets dashboardOuterPadding(BuildContext context) {
    return switch (screenSizeOf(context)) {
      ScreenSize.mobile => const EdgeInsets.all(8),
      ScreenSize.tablet => const EdgeInsets.all(12),
      ScreenSize.desktop => const EdgeInsets.all(16),
      ScreenSize.wide => const EdgeInsets.all(16),
    };
  }

  /// Padding inside the main white content card.
  static EdgeInsets dashboardInnerPadding(BuildContext context) {
    return switch (screenSizeOf(context)) {
      ScreenSize.mobile => const EdgeInsets.all(12),
      ScreenSize.tablet => const EdgeInsets.all(14),
      ScreenSize.desktop => const EdgeInsets.all(18),
      ScreenSize.wide => const EdgeInsets.all(18),
    };
  }

  static double dashboardContentRadius(BuildContext context) {
    return isMobile(context) ? 12 : 18;
  }

  static double sidebarContentGap(BuildContext context) {
    return isMobile(context) ? 0 : 16;
  }

  static double expandedSidebarWidth(BuildContext context) {
    return isTablet(context) ? 220 : 230;
  }

  static const double compactSidebarWidth = 72;

  static double titleFontSize(BuildContext context) {
    return isMobile(context) ? 20 : 28;
  }

  static bool showHeaderDate(BuildContext context) => !isMobile(context);

  static bool showHeaderSubtitle(BuildContext context) => true;

  /// Vertical gap between dashboard home sections.
  static double dashboardSectionGap(BuildContext context) {
    return isMobile(context) ? 12 : 16;
  }

  /// Spacing between metric chips in [ResponsiveMetricGrid].
  static double metricGridSpacing(BuildContext context) {
    return isMobile(context) ? 10 : 12;
  }

  /// Chart / panel height; slightly shorter on mobile.
  static double chartPanelHeight(BuildContext context, {double desktop = 220}) {
    return isMobile(context) ? 200 : desktop;
  }

  /// Fixed panel height on desktop only; intrinsic height on mobile/tablet.
  static double? fixedPanelHeight(BuildContext context, double desktopHeight) {
    return isDesktopOrWider(context) ? desktopHeight : null;
  }

  static bool useDashboardMultiColumn(BuildContext context) => isDesktopOrWider(context);
}
