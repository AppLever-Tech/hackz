import 'package:flutter/material.dart';

import 'data_table_column.dart';

/// Compact, theme-matched tabular view used internally by [ListTableScaffold].
///
/// * Sticky header row with sort affordances (`onSort` is fired with the
///   column's `sortKey` when the header is tapped).
/// * Alternating row tint, virtualised body via `ListView.separated`.
/// * If the sum of column `minWidth`s exceeds the viewport, the table renders
///   horizontally scrollable with fixed widths; otherwise columns stretch via
///   `flex`.
class DataTableView<T> extends StatelessWidget {
  const DataTableView({
    super.key,
    required this.items,
    required this.columns,
    this.onSort,
    this.activeSortKey,
    this.onRowTap,
    this.rowMinHeight = 48,
    this.fixedWidthFallback = 120,
  });

  final List<T> items;
  final List<DataTableColumn<T>> columns;
  final void Function(String sortKey)? onSort;
  final String? activeSortKey;
  final void Function(T row)? onRowTap;
  final double rowMinHeight;

  /// Width used for columns without a `minWidth` when the table is in
  /// horizontal-scroll mode.
  final double fixedWidthFallback;

  static const Color _headerBg = Color(0xFFF1F4FB);
  static const Color _border = Color(0xFFE3E8F4);
  static const Color _altRowBg = Color(0xFFFAFBFE);
  static const Color _headerText = Color(0xFF334155);
  static const Color _activeText = Color(0xFF4A67FF);
  static const Color _mutedText = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalMinWidth = columns.fold<double>(
          0,
          (double sum, DataTableColumn<T> c) => sum + (c.minWidth ?? 0),
        );
        final bool needsHScroll =
            totalMinWidth > 0 && totalMinWidth > constraints.maxWidth;
        final double tableWidth = needsHScroll ? totalMinWidth : constraints.maxWidth;
        final double? tableHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : null;

        final Widget table = SizedBox(
          width: tableWidth,
          height: tableHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                _buildHeader(context, fixedWidths: needsHScroll),
                Expanded(child: _buildBody(context, fixedWidths: needsHScroll)),
              ],
            ),
          ),
        );

        if (!needsHScroll) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: table,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool fixedWidths}) {
    return Container(
      decoration: const BoxDecoration(
        color: _headerBg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < columns.length; i++)
            _wrapCellSlot(
              column: columns[i],
              fixedWidths: fixedWidths,
              child: _headerCell(columns[i]),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(DataTableColumn<T> column) {
    final bool active = column.sortable && column.sortKey == activeSortKey;
    final Color labelColor = active ? _activeText : _headerText;

    final Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            column.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (column.sortable) ...<Widget>[
          const SizedBox(width: 4),
          Icon(
            active ? Icons.arrow_drop_down_rounded : Icons.unfold_more_rounded,
            size: 16,
            color: active ? _activeText : _mutedText,
          ),
        ],
      ],
    );

    final Widget aligned = Align(alignment: column.align, child: label);
    if (!column.sortable || onSort == null) return aligned;
    return InkWell(
      onTap: () => onSort!(column.sortKey!),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: aligned,
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool fixedWidths}) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No records found.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: _border),
      itemBuilder: (BuildContext context, int index) {
        final T row = items[index];
        final Color rowBg = index.isEven ? Colors.white : _altRowBg;
        final Widget rowContent = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < columns.length; i++)
                _wrapCellSlot(
                  column: columns[i],
                  fixedWidths: fixedWidths,
                  child: Align(
                    alignment: columns[i].align,
                    child: columns[i].cell(context, row),
                  ),
                ),
            ],
          ),
        );

        Widget rowWrap = ConstrainedBox(
          constraints: BoxConstraints(minHeight: rowMinHeight),
          child: Container(color: rowBg, child: rowContent),
        );

        if (onRowTap != null) {
          rowWrap = Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onRowTap!(row),
              child: rowWrap,
            ),
          );
        }
        return rowWrap;
      },
    );
  }

  Widget _wrapCellSlot({
    required DataTableColumn<T> column,
    required bool fixedWidths,
    required Widget child,
  }) {
    if (fixedWidths) {
      return SizedBox(
        width: column.minWidth ?? fixedWidthFallback,
        child: child,
      );
    }
    return Expanded(flex: column.flex, child: child);
  }
}
