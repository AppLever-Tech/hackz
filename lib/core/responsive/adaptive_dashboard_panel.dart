import 'package:flutter/material.dart';

import 'responsive_helper.dart';
import '../../../screens/common/dashboard_components.dart';

/// Section container with optional fixed height on desktop (scrollable inside).
class AdaptiveDashboardPanel extends StatelessWidget {
  const AdaptiveDashboardPanel({
    super.key,
    required this.child,
    this.desktopHeight,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final double? desktopHeight;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final fixedHeight = desktopHeight == null
        ? null
        : ResponsiveHelper.fixedPanelHeight(context, desktopHeight!);

    // Bounded height only — do not wrap in [SingleChildScrollView], which gives
    // unbounded max height and breaks [Expanded] inside panel children.
    final Widget body = fixedHeight == null
        ? child
        : SizedBox(
            height: fixedHeight,
            child: ClipRect(child: child),
          );

    return SectionContainer(
      padding: padding ?? EdgeInsets.all(ResponsiveHelper.isMobile(context) ? 12 : 14),
      borderRadius: borderRadius ?? (ResponsiveHelper.isMobile(context) ? 12 : 16),
      child: body,
    );
  }
}

/// Fixed-height chart area inside a [ChartCard] or section.
class ResponsiveChartBox extends StatelessWidget {
  const ResponsiveChartBox({
    super.key,
    required this.child,
    this.desktopHeight = 220,
  });

  final Widget child;
  final double desktopHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ResponsiveHelper.chartPanelHeight(context, desktop: desktopHeight),
      child: child,
    );
  }
}
