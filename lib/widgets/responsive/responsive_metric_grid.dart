import 'package:flutter/material.dart';

import '../../responsive/responsive_breakpoints.dart';
import '../../responsive/responsive_helper.dart';

/// Wraps [children] into a responsive grid using [Wrap] (no horizontal overflow).
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.spacing = 12,
    this.runSpacing = 12,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || children.isEmpty) {
          return const SizedBox.shrink();
        }

        int columns = (maxWidth / minTileWidth).floor().clamp(1, maxColumns);
        if (ResponsiveHelper.isMobile(context) && columns > 1 && maxWidth < ResponsiveBreakpoints.mobile) {
          columns = 1;
        }

        final tileWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((Widget child) => SizedBox(width: tileWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}
