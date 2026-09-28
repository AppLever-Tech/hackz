/// App-wide layout breakpoints. Do not use ad-hoc values in feature screens.
abstract final class ResponsiveBreakpoints {
  /// Viewport width strictly below this is [ScreenSize.mobile].
  static const double mobile = 600;

  /// Viewport width from [mobile] up to (not including) [tablet] is [ScreenSize.tablet].
  static const double tablet = 900;

  /// Viewport width at or above [wide] is [ScreenSize.wide]; between [tablet] and [wide] is desktop.
  static const double wide = 1200;

  /// Parent width below this uses stacked/card layouts (right-side workspace panel).
  static const double compactPane = 560;
}

/// Canonical screen bucket for adaptive layouts.
enum ScreenSize {
  mobile,
  tablet,
  desktop,
  wide,
}
