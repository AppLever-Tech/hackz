import 'package:flutter/widgets.dart';

import '../../responsive/responsive_helper.dart';
import 'data_table_column.dart';
import 'data_table_view.dart';
import 'view_mode.dart';

/// Picks list vs table rendering for a list dashboard.
///
/// * On mobile, list mode is forced regardless of [mode] (tables don't fit on
///   phones — better UX, less code than horizontal-scroll fallback).
/// * In list mode, [listBuilder] is invoked verbatim (consumers keep their
///   existing `ListView.builder` + cards).
/// * In table mode, a shared [DataTableView] renders [columns] over [items].
///
/// Empty / loading states stay with the caller (the existing FutureBuilder /
/// metrics row pattern is unchanged).
class ListTableScaffold<T> extends StatelessWidget {
  const ListTableScaffold({
    super.key,
    required this.mode,
    required this.items,
    required this.columns,
    required this.listBuilder,
    this.onSort,
    this.activeSortKey,
    this.onRowTap,
  });

  final DataViewMode mode;
  final List<T> items;
  final List<DataTableColumn<T>> columns;
  final Widget Function(List<T> items) listBuilder;
  final void Function(String sortKey)? onSort;
  final String? activeSortKey;
  final void Function(T row)? onRowTap;

  /// Effective view mode after applying mobile override.
  static DataViewMode effectiveMode(BuildContext context, DataViewMode mode) {
    if (ResponsiveHelper.isMobile(context)) return DataViewMode.list;
    return mode;
  }

  @override
  Widget build(BuildContext context) {
    if (effectiveMode(context, mode) == DataViewMode.list) {
      return listBuilder(items);
    }
    return DataTableView<T>(
      items: items,
      columns: columns,
      onSort: onSort,
      activeSortKey: activeSortKey,
      onRowTap: onRowTap,
    );
  }
}
