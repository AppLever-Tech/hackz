import 'package:flutter/material.dart';

import 'responsive_helper.dart';

/// Scrollable dashboard body wrapper. Use for overview pages with column content.
///
/// Set [scrollable] to false when the child manages its own scroll (tabs, lists with [Expanded]).
class DashboardScrollableBody extends StatelessWidget {
  const DashboardScrollableBody({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding,
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (!scrollable) {
      return child;
    }
    return SingleChildScrollView(
      padding: padding ?? EdgeInsets.zero,
      primary: false,
      child: Align(
        alignment: Alignment.topLeft,
        widthFactor: 1,
        child: child,
      ),
    );
  }
}

/// Fills remaining dashboard height; defers scrolling to [child] when it uses [Expanded].
class DashboardBodySlot extends StatelessWidget {
  const DashboardBodySlot({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: child,
        );
      },
    );
  }
}

/// Recommended gap below the dashboard header before body content.
double dashboardHeaderBodyGap(BuildContext context) {
  return ResponsiveHelper.isMobile(context) ? 12 : 16;
}
