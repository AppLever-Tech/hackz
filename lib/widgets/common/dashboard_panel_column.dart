import 'package:flutter/material.dart';

/// Dashboard card body: fixed [headers] plus a scrollable list region.
///
/// When the parent height is bounded (desktop fixed panel), the list expands
/// into remaining space. When unbounded (stacked mobile), the list uses its
/// intrinsic capped height.
class DashboardPanelColumn extends StatelessWidget {
  const DashboardPanelColumn({
    super.key,
    required this.headers,
    required this.listBuilder,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> headers;
  final Widget Function({required bool expandVertically}) listBuilder;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool inFixedPanel = constraints.maxHeight.isFinite;
        final Widget list = listBuilder(expandVertically: inFixedPanel);
        return Column(
          crossAxisAlignment: crossAxisAlignment,
          children: <Widget>[
            ...headers,
            if (inFixedPanel) Expanded(child: list) else list,
          ],
        );
      },
    );
  }
}
