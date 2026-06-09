import 'package:flutter/material.dart';

import 'responsive_helper.dart';

/// Builds different widgets per [ScreenSize] without repeating [MediaQuery] checks.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper.screenSizeOf(context));
  }
}

/// Picks the first matching builder for the current [ScreenSize].
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    this.mobile,
    this.tablet,
    required this.desktop,
    this.wide,
  });

  final WidgetBuilder? mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder desktop;
  final WidgetBuilder? wide;

  @override
  Widget build(BuildContext context) {
    return switch (ResponsiveHelper.screenSizeOf(context)) {
      ScreenSize.mobile => (mobile ?? desktop).call(context),
      ScreenSize.tablet => (tablet ?? desktop).call(context),
      ScreenSize.desktop => desktop(context),
      ScreenSize.wide => (wide ?? desktop).call(context),
    };
  }
}

/// Convenience: mobile vs everything else (tablet uses [tabletOrDesktop] or [desktop]).
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.mobile,
    required this.desktop,
    this.tablet,
    this.wide,
  });

  final T mobile;
  final T desktop;
  final T? tablet;
  final T? wide;

  T resolve(BuildContext context) {
    return switch (ResponsiveHelper.screenSizeOf(context)) {
      ScreenSize.mobile => mobile,
      ScreenSize.tablet => tablet ?? desktop,
      ScreenSize.desktop => desktop,
      ScreenSize.wide => wide ?? desktop,
    };
  }
}
