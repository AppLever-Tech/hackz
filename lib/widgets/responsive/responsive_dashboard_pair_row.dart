import 'package:flutter/material.dart';

import '../../responsive/responsive_breakpoints.dart';
import 'responsive_columns.dart';

/// Wraps a [ResponsivePair] with a fixed height only when the pair lays out
/// side-by-side (available width at or above [breakpoint]).
///
/// Uses [LayoutBuilder] width — not [MediaQuery] — so sidebar layouts do not
/// apply a fixed height while the pair is still stacking vertically.
class ResponsiveDashboardPairRow extends StatelessWidget {
  const ResponsiveDashboardPairRow({
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
