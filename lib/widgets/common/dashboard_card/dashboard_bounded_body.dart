import 'package:flutter/material.dart';

/// Dashboard card body: fixed [headers] plus a region that expands in bounded panels.
///
/// When the parent height is bounded (desktop fixed panel), [bodyBuilder] receives
/// `expandVertically: true` and is wrapped in [Expanded]. When unbounded (stacked
/// mobile inside [SingleChildScrollView]), the body uses its intrinsic height.
class DashboardBoundedBody extends StatelessWidget {
  const DashboardBoundedBody({
    super.key,
    required this.headers,
    required this.bodyBuilder,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> headers;
  final Widget Function({required bool expandVertically}) bodyBuilder;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool inFixedPanel = constraints.maxHeight.isFinite;
        final Widget body = bodyBuilder(expandVertically: inFixedPanel);
        return Column(
          crossAxisAlignment: crossAxisAlignment,
          children: <Widget>[
            ...headers,
            if (inFixedPanel) Expanded(child: body) else body,
          ],
        );
      },
    );
  }
}
