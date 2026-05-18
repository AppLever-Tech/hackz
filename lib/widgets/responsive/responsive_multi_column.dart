import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';

/// Stacks children vertically on mobile/tablet; horizontal row on desktop+.
class ResponsiveMultiColumn extends StatelessWidget {
  const ResponsiveMultiColumn({
    super.key,
    required this.children,
    this.flexes,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : assert(children.length >= 2);

  final List<Widget> children;
  final List<int>? flexes;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.useDashboardMultiColumn(context)) {
      final flexValues = flexes ?? List<int>.filled(children.length, 1);
      return Row(
        crossAxisAlignment: crossAxisAlignment,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) SizedBox(width: spacing),
            Expanded(flex: flexValues[i.clamp(0, flexValues.length - 1)], child: children[i]),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}
