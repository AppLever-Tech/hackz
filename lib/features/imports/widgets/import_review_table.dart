import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';

class ImportReviewTable extends StatefulWidget {
  const ImportReviewTable({
    super.key,
    required this.rows,
    required this.columns,
    this.expansionColumns = const <ImportReviewColumn>[],
  });

  final List<ImportReviewRow> rows;
  final List<ImportReviewColumn> columns;
  final List<ImportReviewColumn> expansionColumns;

  @override
  State<ImportReviewTable> createState() => _ImportReviewTableState();
}

class _ImportReviewTableState extends State<ImportReviewTable> {
  final Set<int> _expandedRows = <int>{};

  @override
  Widget build(BuildContext context) {
    if (widget.expansionColumns.isEmpty) return _buildDataTable();
    return _buildExpandableList();
  }

  Widget _buildDataTable() {
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
            ...widget.columns.map(
              (ImportReviewColumn c) => DataColumn(
                label: Text(c.label, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: widget.rows
              .map(
                (ImportReviewRow row) => DataRow(
                  cells: <DataCell>[
                    DataCell(Text('${row.rowNumber}')),
                    ...widget.columns.map(
                      (ImportReviewColumn c) => DataCell(_TruncatedText(text: row.valueFor(c.key))),
                    ),
                    DataCell(_StatusCell(row: row)),
                  ],
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildExpandableList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _header(),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        ...widget.rows.map(_expandableRow),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 28),
          const SizedBox(
            width: 40,
            child: Text('Row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
          for (var i = 0; i < widget.columns.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              flex: i == 0 ? 2 : 3,
              child: Text(
                widget.columns[i].label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
          const SizedBox(width: 12),
          const SizedBox(
            width: 120,
            child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _expandableRow(ImportReviewRow row) {
    final bool canExpand = widget.expansionColumns.any((ImportReviewColumn c) => row.valueFor(c.key).isNotEmpty);
    final bool expanded = canExpand && _expandedRows.contains(row.rowNumber);
    final Map<String, String> cells = <String, String>{
      for (final ImportReviewColumn column in widget.columns) column.key: row.valueFor(column.key),
    };

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: canExpand
                ? () => setState(() {
                      if (expanded) {
                        _expandedRows.remove(row.rowNumber);
                      } else {
                        _expandedRows.add(row.rowNumber);
                      }
                    })
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 28,
                    child: canExpand
                        ? Icon(
                            expanded ? AppIcons.expandLess : AppIcons.expandMore,
                            size: 18,
                            color: const Color(0xFF64748B),
                          )
                        : null,
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${row.rowNumber}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
                  for (var i = 0; i < widget.columns.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: i == 0 ? 2 : 3,
                      child: _TruncatedText(text: cells[widget.columns[i].key] ?? ''),
                    ),
                  ],
                  const SizedBox(width: 12),
                  SizedBox(width: 120, child: _StatusCell(row: row)),
                ],
              ),
            ),
          ),
          if (expanded) _expansionPanel(row),
        ],
      ),
    );
  }

  Widget _expansionPanel(ImportReviewRow row) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 0, 12, 12),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool stack = !constraints.hasBoundedWidth || constraints.maxWidth < 640;
          final List<Widget> fields = widget.expansionColumns
              .map(
                (ImportReviewColumn column) => _NamedValueField(
                  label: column.label,
                  value: row.valueFor(column.key),
                ),
              )
              .toList(growable: false);

          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < fields.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 8),
                  fields[i],
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var i = 0; i < fields.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: fields[i]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ImportReviewColumn {
  const ImportReviewColumn({required this.key, required this.label});

  final String key;
  final String label;
}

class _TruncatedText extends StatelessWidget {
  const _TruncatedText({required this.text});

  final String text;

  static const TextStyle _style = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A),
  );

  @override
  Widget build(BuildContext context) {
    final String value = text.trim();
    if (value.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 240;
        final TextPainter painter = TextPainter(
          text: TextSpan(text: value, style: _style),
          maxLines: 1,
          ellipsis: '…',
          textDirection: Directionality.of(context),
        )..layout(maxWidth: maxWidth);
        final bool overflowed = painter.didExceedMaxLines;

        final Widget label = Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _style,
        );

        if (!overflowed) return label;
        return Tooltip(
          message: value,
          waitDuration: const Duration(milliseconds: 250),
          child: label,
        );
      },
    );
  }
}

class _NamedValueField extends StatelessWidget {
  const _NamedValueField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String display = value.trim().isEmpty ? '—' : value.trim();
    return InputDecorator(
      decoration: HackzInputDecoration.decorate(
        labelText: label,
        fillColorOverride: const Color(0xFFF8FAFC),
        contentPaddingOverride: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      child: Text(
        display,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: value.trim().isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
        ),
      ),
    );
  }
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
