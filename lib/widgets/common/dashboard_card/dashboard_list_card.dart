import 'package:flutter/material.dart';

import 'dashboard_bounded_body.dart';
import 'dashboard_list_preset.dart';
import 'dashboard_scrollable_list.dart';

/// Dashboard card with a header block and capped scrollable list body.
class DashboardListCard extends StatelessWidget {
  const DashboardListCard({
    super.key,
    required this.headers,
    required this.itemCount,
    required this.itemBuilder,
    this.preset = DashboardListPreset.compact,
    this.separatorHeight,
    this.padding = EdgeInsets.zero,
    this.empty,
    this.emptyHeight,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> headers;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final DashboardListPreset preset;
  final double? separatorHeight;
  final EdgeInsetsGeometry padding;
  final Widget? empty;
  final double? emptyHeight;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return DashboardBoundedBody(
      crossAxisAlignment: crossAxisAlignment,
      headers: headers,
      bodyBuilder: ({required bool expandVertically}) => DashboardScrollableList(
        expandVertically: expandVertically,
        itemCount: itemCount,
        preset: preset,
        separatorHeight: separatorHeight,
        padding: padding,
        empty: empty,
        emptyHeight: emptyHeight,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
