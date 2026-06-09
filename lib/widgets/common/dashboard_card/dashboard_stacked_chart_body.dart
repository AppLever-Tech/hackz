import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import 'dashboard_bounded_body.dart';
import 'dashboard_layout_tokens.dart';

/// Chart region that expands in bounded panels or uses a fixed height when stacked.
class DashboardStackedChartBody extends StatelessWidget {
  const DashboardStackedChartBody({
    super.key,
    required this.headers,
    required this.chart,
    this.fallbackHeight = DashboardLayoutTokens.stackedChartHeight,
  });

  final List<Widget> headers;
  final Widget chart;
  final double fallbackHeight;

  @override
  Widget build(BuildContext context) {
    return DashboardBoundedBody(
      headers: headers,
      bodyBuilder: ({required bool expandVertically}) {
        if (expandVertically) {
          return chart;
        }
        return SizedBox(
          height: ResponsiveHelper.chartPanelHeight(context, desktop: fallbackHeight),
          child: chart,
        );
      },
    );
  }
}
