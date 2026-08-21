import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/form_value_row.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../constants/import_constants.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _header(compact: ResponsiveHelper.isMobile(context)),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        Expanded(
          child: ListView.builder(
            itemCount: widget.rows.length,
            itemBuilder: (BuildContext context, int index) => _expandableRow(widget.rows[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 720),
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 88,
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
      ),
    );
  }

  Widget _header({required bool compact}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 28),
          SizedBox(
            width: compact ? 28 : 40,
            child: const Text('Row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          ),
          if (!compact) ...<Widget>[
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
            const Expanded(
              flex: 3,
              child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ),
          ] else
            const Expanded(
              child: Text('Problem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ),
        ],
      ),
    );
  }

  bool _canExpand(ImportReviewRow row) {
    if (row.metadata['expandable'] == '1') return true;
    return widget.expansionColumns.any((ImportReviewColumn c) => row.valueFor(c.key).isNotEmpty);
  }

  Widget _expandableRow(ImportReviewRow row) {
    final bool canExpand = _canExpand(row);
    final bool expanded = canExpand && _expandedRows.contains(row.rowNumber);
    final bool compact = ResponsiveHelper.isMobile(context);

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
              child: compact ? _compactCollapsed(row, canExpand: canExpand, expanded: expanded) : _wideCollapsed(row, canExpand: canExpand, expanded: expanded),
            ),
          ),
          if (expanded) _expansionPanel(row, compact: compact),
        ],
      ),
    );
  }

  Widget _wideCollapsed(ImportReviewRow row, {required bool canExpand, required bool expanded}) {
    return Row(
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
            child: _TruncatedText(text: row.valueFor(widget.columns[i].key)),
          ),
        ],
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _StatusCell(row: row),
        ),
      ],
    );
  }

  Widget _compactCollapsed(ImportReviewRow row, {required bool canExpand, required bool expanded}) {
    final String title = widget.columns.isNotEmpty ? row.valueFor(widget.columns.first.key) : '';
    final String description = widget.columns.length > 1 ? row.valueFor(widget.columns[1].key) : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          width: 28,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${row.rowNumber}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TruncatedText(text: title),
              if (description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                _TruncatedText(text: description, muted: true),
              ],
              const SizedBox(height: 4),
              _StatusCell(row: row),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expansionPanel(ImportReviewRow row, {required bool compact}) {
    final List<ImportReviewColumn> provided = widget.expansionColumns
        .where((ImportReviewColumn column) => row.valueFor(column.key).isNotEmpty)
        .toList(growable: false);
    if (provided.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 72, 0, 12, 10),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool twoCol = constraints.hasBoundedWidth && constraints.maxWidth >= 520 && provided.length > 1;
          final List<Widget> tiles = provided
              .map(
                (ImportReviewColumn column) => _DetailTile(
                  icon: _iconFor(column.key),
                  label: column.label,
                  value: row.valueFor(column.key),
                ),
              )
              .toList(growable: false);

          if (!twoCol) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var i = 0; i < tiles.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 6),
                  tiles[i],
                ],
              ],
            );
          }

          final List<Widget> rows = <Widget>[];
          for (var i = 0; i < tiles.length; i += 2) {
            if (i > 0) rows.add(const SizedBox(height: 6));
            if (i + 1 < tiles.length) {
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: tiles[i]),
                    const SizedBox(width: 8),
                    Expanded(child: tiles[i + 1]),
                  ],
                ),
              );
            } else {
              rows.add(tiles[i]);
            }
          }
          return Column(children: rows);
        },
      ),
    );
  }

  IconData _iconFor(String key) {
    return switch (key) {
      ImportConstants.externalProblemIdColumnKey => AppIcons.key,
      ImportConstants.themeColumnKey => AppIcons.orgType,
      ImportConstants.issuingOrganisationColumnKey => AppIcons.organizations,
      ImportConstants.issuingDepartmentColumnKey => AppIcons.departments,
      ImportConstants.teamNameColumnKey => AppIcons.teams,
      ImportConstants.phoneColumnKey => AppIcons.student,
      ImportConstants.organisationColumnKey => AppIcons.organizations,
      ImportConstants.departmentColumnKey => AppIcons.departments,
      ImportConstants.isTeamLeaderColumnKey => AppIcons.users,
      _ => AppIcons.info,
    };
  }
}

class ImportReviewColumn {
  const ImportReviewColumn({required this.key, required this.label});

  final String key;
  final String label;
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String display = value.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: HackzInputDecoration.pickerDecoration(),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 13, color: EntityCardStyles.fieldLabel.color),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EntityCardStyles.fieldLabel,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TruncatedText(text: display),
          ),
        ],
      ),
    );
  }
}

class _TruncatedText extends StatelessWidget {
  const _TruncatedText({required this.text, this.muted = false});

  final String text;
  final bool muted;

  TextStyle get _style => TextStyle(
        fontSize: muted ? 12 : 13,
        fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
        color: muted ? const Color(0xFF64748B) : const Color(0xFF0F172A),
      );

  @override
  Widget build(BuildContext context) {
    final String value = text.trim();
    if (value.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));
    }

    final TextStyle style = _style;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 240;
        final TextPainter painter = TextPainter(
          text: TextSpan(text: value, style: style),
          maxLines: 1,
          ellipsis: '…',
          textDirection: Directionality.of(context),
        )..layout(maxWidth: maxWidth);
        final bool overflowed = painter.didExceedMaxLines;

        final Widget label = Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
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
    final String detail = row.messages.isNotEmpty ? row.messages.join('\n') : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          row.statusLabel,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
        if (detail.isNotEmpty)
          Text(
            detail,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
      ],
    );
  }
}
