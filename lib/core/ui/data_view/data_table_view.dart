import 'package:flutter/material.dart';

import 'data_table_column.dart';

/// Compact, theme-matched tabular view for list dashboards (e.g. ideas list).
///
/// * Sticky header row with sort affordances (`onSort` is fired with the
///   column's `sortKey` when the header is tapped).
/// * Alternating row tint, virtualised body via `ListView.separated`.
/// * If the sum of column `minWidth`s plus inter-column gaps exceeds the
///   viewport, the table renders horizontally scrollable with fixed widths;
///   otherwise columns stretch via `flex`.
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

  static const double _horizontalPadding = 24;

  double _rowContentWidth() {
    var width = 0.0;
    for (final DataTableColumn<T> column in columns) {
      width += column.fixedWidth ?? column.minWidth ?? fixedWidthFallback;
      width += _gapAfter(column);
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double contentWidth = _rowContentWidth();
        final bool needsHScroll =
            contentWidth > 0 && contentWidth + _horizontalPadding > constraints.maxWidth;
        final double tableWidth =
            needsHScroll ? contentWidth + _horizontalPadding : constraints.maxWidth;
        final bool boundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

        final Widget table = DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(context, fixedWidths: needsHScroll),
                Expanded(
                  child: ClipRect(
                    child: _buildBody(context, fixedWidths: needsHScroll),
                  ),
                ),
              ],
            ),
          ),
        );

        // Let the parent Expanded supply vertical space; forcing maxHeight here
        // can overshoot flex allocation and trigger Column overflow.
        if (!needsHScroll) return table;

        // Horizontal scroll child needs an explicit cross-axis extent so the
        // inner Column + ListView do not expand to full content height.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            height: boundedHeight ? constraints.maxHeight : null,
            child: table,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < columns.length; i++) ...<Widget>[
            _wrapCellSlot(
              column: columns[i],
              fixedWidths: fixedWidths,
              child: _headerCell(columns[i]),
            ),
            if (_gapAfter(columns[i]) > 0) SizedBox(width: _gapAfter(columns[i])),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(DataTableColumn<T> column) {
    final bool active = column.sortable && column.sortKey == activeSortKey;
    final Color labelColor = active ? _activeText : _headerText;

    final Widget label = Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: column.align,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    column.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: column.align == Alignment.center ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (column.sortable) ...<Widget>[
                  const SizedBox(width: 2),
                  Icon(
                    active ? Icons.arrow_drop_down_rounded : Icons.unfold_more_rounded,
                    size: 14,
                    color: active ? _activeText : _mutedText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    if (!column.sortable || onSort == null) return label;
    return InkWell(
      onTap: () => onSort!(column.sortKey!),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: label,
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool fixedWidths}) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < columns.length; i++) ...<Widget>[
                _wrapCellSlot(
                  column: columns[i],
                  fixedWidths: fixedWidths,
                  child: columns[i].cell(context, row),
                ),
                if (_gapAfter(columns[i]) > 0) SizedBox(width: _gapAfter(columns[i])),
              ],
            ],
          ),
        );

        Widget rowWrap = Container(color: rowBg, child: rowContent);

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

  double _gapAfter(DataTableColumn<T> column) => column.gapAfter ?? 0;

  Widget _wrapCellSlot({
    required DataTableColumn<T> column,
    required bool fixedWidths,
    required Widget child,
  }) {
    final Widget bounded = ClipRect(
      child: Align(
        alignment: column.align,
        child: child,
      ),
    );

    if (column.fixedWidth != null) {
      return SizedBox(width: column.fixedWidth, child: bounded);
    }
    if (fixedWidths) {
      return SizedBox(
        width: column.minWidth ?? fixedWidthFallback,
        child: bounded,
      );
    }
    return Expanded(flex: column.flex, child: bounded);
  }
}
