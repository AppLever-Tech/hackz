import 'package:flutter/material.dart';

import '../../responsive/responsive_breakpoints.dart';
import '../../responsive/responsive_helper.dart';

/// Stacks two children vertically below [ResponsiveBreakpoints.tablet], otherwise [Row].
class ResponsivePair extends StatelessWidget {
  const ResponsivePair({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.spacing = 16,
    this.breakpoint = ResponsiveBreakpoints.tablet,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget first;
  final Widget second;
  final int firstFlex;
  final int secondFlex;
  final double spacing;
  final double breakpoint;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              first,
              SizedBox(height: spacing),
              second,
            ],
          );
        }
        final CrossAxisAlignment rowCrossAxisAlignment =
            crossAxisAlignment == CrossAxisAlignment.stretch && !constraints.maxHeight.isFinite
                ? CrossAxisAlignment.start
                : crossAxisAlignment;
        return Row(
          crossAxisAlignment: rowCrossAxisAlignment,
          children: <Widget>[
            Expanded(flex: firstFlex, child: first),
            SizedBox(width: spacing),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }
}

/// Alias for [ResponsivePair] (naming parity with product docs).
typedef ResponsiveColumns = ResponsivePair;
