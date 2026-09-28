import 'package:flutter/material.dart';

import 'dashboard_layout_tokens.dart';
import 'dashboard_list_preset.dart';

/// Scrollable dashboard list capped at [DashboardLayoutTokens.listMaxVisibleRows].
class DashboardScrollableList extends StatelessWidget {
  const DashboardScrollableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.preset = DashboardListPreset.compact,
    this.rowStride,
    this.separatorHeight,
    this.padding = EdgeInsets.zero,
    this.empty,
    this.emptyHeight,
    this.expandVertically = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final DashboardListPreset preset;
  final double? rowStride;
  final double? separatorHeight;
  final EdgeInsetsGeometry padding;
  final Widget? empty;
  final double? emptyHeight;
  final bool expandVertically;

  static int visibleRowCount(int itemCount) =>
      itemCount > DashboardLayoutTokens.listMaxVisibleRows
          ? DashboardLayoutTokens.listMaxVisibleRows
          : itemCount;

  static bool shouldScroll(int itemCount) =>
      itemCount > DashboardLayoutTokens.listMaxVisibleRows;

  static double cappedListHeight(
    int itemCount, {
    required double rowStride,
    double separatorHeight = 0,
  }) {
    final int rows = visibleRowCount(itemCount);
    if (rows == 0) {
      return 0;
    }
    return rows * rowStride + (rows > 1 ? (rows - 1) * separatorHeight : 0);
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      final Widget emptyWidget = empty ?? const SizedBox.shrink();
      if (emptyHeight == null) {
        return emptyWidget;
      }
      return SizedBox(height: emptyHeight, child: emptyWidget);
    }

    final double gap = separatorHeight ?? preset.separatorHeight;
    final Widget list = ListView.separated(
      padding: padding,
      shrinkWrap: !expandVertically,
      physics: expandVertically
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: gap),
      itemBuilder: itemBuilder,
    );

    if (expandVertically) {
      return list;
    }

    // Stacked dashboard cards (mobile): let rows use their natural height so
    // variable-height items (e.g. payment queue cards) are not clipped.
    return list;
  }
}
