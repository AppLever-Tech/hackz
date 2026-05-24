import 'package:flutter/material.dart';

/// Shared row cap and stride tokens for dynamic dashboard lists.
abstract final class DashboardScrollableListLayout {
  /// Maximum visible rows before the list scrolls internally.
  static const int maxVisibleRows = 5;

  /// Compact pill / preview rows (problems, ideas).
  static const double compactRowStride = 44;
  static const double compactSeparatorHeight = 8;

  /// Activity event rows (icon + title + subtitle).
  static const double activityRowStride = 60;
  static const double activitySeparatorHeight = 12;

  /// Department activity rows (two-line subtitle).
  static const double departmentActivityRowStride = 64;
  static const double departmentActivitySeparatorHeight = 9;

  /// Alert card rows (titled message blocks).
  static const double alertRowStride = 72;
  static const double alertSeparatorHeight = 10;

  static int visibleRowCount(int itemCount) =>
      itemCount > maxVisibleRows ? maxVisibleRows : itemCount;

  static bool shouldScroll(int itemCount) => itemCount > maxVisibleRows;

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
}

/// Scrollable dashboard list capped at [DashboardScrollableListLayout.maxVisibleRows].
///
/// Set [expandVertically] when placed inside [Expanded] via [DashboardPanelColumn]
/// (fixed-height desktop panels). Leave false for unbounded stacked mobile layouts.
class DashboardScrollableList extends StatelessWidget {
  const DashboardScrollableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.rowStride,
    this.separatorHeight = 0,
    this.padding = EdgeInsets.zero,
    this.empty,
    this.emptyHeight,
    this.expandVertically = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double rowStride;
  final double separatorHeight;
  final EdgeInsetsGeometry padding;
  final Widget? empty;
  final double? emptyHeight;
  final bool expandVertically;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      final Widget emptyWidget = empty ?? const SizedBox.shrink();
      if (emptyHeight == null) {
        return emptyWidget;
      }
      return SizedBox(height: emptyHeight, child: emptyWidget);
    }

    final bool scrolls = DashboardScrollableListLayout.shouldScroll(itemCount);
    final Widget list = ListView.separated(
      padding: padding,
      physics: scrolls || expandVertically
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
      itemBuilder: itemBuilder,
    );

    if (expandVertically) {
      return list;
    }

    return SizedBox(
      height: DashboardScrollableListLayout.cappedListHeight(
        itemCount,
        rowStride: rowStride,
        separatorHeight: separatorHeight,
      ),
      width: double.infinity,
      child: list,
    );
  }
}
