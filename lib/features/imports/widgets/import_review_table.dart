import 'package:flutter/material.dart';

import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';

class ImportReviewTable extends StatelessWidget {
  const ImportReviewTable({
    super.key,
    required this.rows,
    required this.columns,
  });

  final List<ImportReviewRow> rows;
  final List<ImportReviewColumn> columns;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 720),
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 56,
          columnSpacing: 16,
          columns: <DataColumn>[
            const DataColumn(label: Text('Row', style: TextStyle(fontWeight: FontWeight.w800))),
            ...columns.map(
              (ImportReviewColumn c) => DataColumn(
                label: Text(c.label, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: rows
              .map(
                (ImportReviewRow row) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text('${row.rowNumber}')),
                    ...columns.map((ImportReviewColumn c) => DataCell(Text(row.valueFor(c.key)))),
                    DataCell(_StatusCell(row: row)),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class ImportReviewColumn {
  const ImportReviewColumn({required this.key, required this.label});

  final String key;
  final String label;
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.row});

  final ImportReviewRow row;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (row.severity) {
      ImportRowSeverity.valid => const Color(0xFF047857),
      ImportRowSeverity.warning => const Color(0xFFB45309),
      ImportRowSeverity.error => const Color(0xFFB91C1C),
    };
    final String dept = row.metadata['departmentName'] ?? '';
    final String detail = row.messages.isNotEmpty ? row.messages.first : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          row.statusLabel,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
        if (detail.isNotEmpty) _StatusDetailText(detail: detail, color: color),
        if (dept.isNotEmpty)
          Text(
            dept,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
      ],
    );
  }
}

/// Inline status detail — compact by default; full text in a hover tooltip when verbose.
class _StatusDetailText extends StatelessWidget {
  const _StatusDetailText({required this.detail, required this.color});

  static const int _tooltipCharThreshold = 48;

  final String detail;
  final Color color;

  bool get _useTooltip => detail.contains('\n') || detail.length > _tooltipCharThreshold;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: color.withValues(alpha: 0.9),
    );

    final Widget text = Text(
      _useTooltip ? _singleLinePreview(detail) : detail,
      maxLines: _useTooltip ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );

    if (!_useTooltip) return text;

    return Tooltip(
      message: detail,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 300),
      child: text,
    );
  }

  static String _singleLinePreview(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
