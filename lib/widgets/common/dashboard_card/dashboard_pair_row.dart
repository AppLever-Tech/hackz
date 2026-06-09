import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../core/responsive/responsive_columns.dart';

/// Wraps a [ResponsivePair] with a fixed height only when the pair lays out side-by-side.
class DashboardPairRow extends StatelessWidget {
  const DashboardPairRow({
    super.key,
    required this.height,
    required this.pair,
    this.breakpoint = ResponsiveBreakpoints.tablet,
  });

  final double height;
  final ResponsivePair pair;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < breakpoint) {
          return pair;
        }
        return SizedBox(height: height, child: pair);
      },
    );
  }
}
