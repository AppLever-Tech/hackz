import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';

/// Wraps [children] into a responsive grid using [Wrap] (no horizontal overflow).
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.children,
    this.minTileWidth = 240,
    this.spacing,
    this.runSpacing,
    this.maxColumns = 4,
    this.useStandardColumns = true,
  });

  final List<Widget> children;
  final double minTileWidth;

  /// When null, uses [ResponsiveHelper.metricGridSpacing].
  final double? spacing;
  final double? runSpacing;
  final int maxColumns;

  /// When true and [maxColumns] is 4, uses 1 / 2 / 4 columns by screen size.
  final bool useStandardColumns;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? ResponsiveHelper.metricGridSpacing(context);
    final runGap = runSpacing ?? gap;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || children.isEmpty) {
          return const SizedBox.shrink();
        }

        final int columns;
        if (useStandardColumns && maxColumns >= 4) {
          columns = ResponsiveHelper.standardMetricColumns(context);
        } else {
          columns = (maxWidth / minTileWidth).floor().clamp(1, maxColumns);
        }

        final tileWidth = (maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: runGap,
          children: children
              .map((Widget child) => SizedBox(width: tileWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}
