import 'package:flutter/widgets.dart';

/// Column descriptor used by [DataTableView] / [ListTableScaffold].
///
/// Per-feature factories (e.g. `IdeaTableColumns.build(...)`) construct a list
/// of these and pass it to the shared scaffold; cells are still rendered with
/// each feature's existing pills/chips/buttons.
@immutable
class DataTableColumn<T> {
  const DataTableColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.minWidth,
    this.align = Alignment.centerLeft,
    this.sortKey,
    this.gapAfter,
  });

  /// Header label shown in the table head.
  final String label;

  /// Cell widget builder. Reuse existing pills/chips/buttons here — keep
  /// builders lean (no padding decorations) so the scaffold can manage row
  /// height and alternation consistently.
  final Widget Function(BuildContext context, T row) cell;

  /// Column flex weight when the table fits in the viewport. Ignored when the
  /// scaffold falls back to fixed widths (horizontal scroll).
  final int flex;

  /// Minimum width hint. When the sum of all min-widths exceeds the viewport,
  /// the table renders horizontally scrollable with fixed widths.
  final double? minWidth;

  /// Alignment for both the header label and the rendered cell.
  final Alignment align;

  /// Stable key passed to `onSort(...)` when this column header is tapped.
  /// `null` means the column is not sortable.
  final String? sortKey;

  bool get sortable => sortKey != null;

  /// Optional horizontal gap inserted after this column (header + body).
  final double? gapAfter;
}
