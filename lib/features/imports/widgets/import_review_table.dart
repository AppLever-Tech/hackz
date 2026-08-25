import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/form_value_row.dart';
import '../../../core/ui/common/mobile_row_card_icon_action.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../constants/import_constants.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';
import 'import_review_title_display.dart';

/// Shared review-table metrics for problem and user CSV import.
abstract final class ImportReviewColumnLayout {
  ImportReviewColumnLayout._();

  static const double expand = 20;
  static const double rowNumber = 28;
  static const double phone = 88;
  static const double role = 104;
  static const double teamLeader = 88;
  static const double status = 132;
  static const double actions = 72;
  static const double gap = 8;
  static const double compactBreakpoint = 760;
}

class ImportReviewColumn {
  const ImportReviewColumn({
    required this.key,
    required this.label,
    this.width,
    this.flex,
    this.center = false,
  });

  final String key;
  final String label;
  final double? width;
  final int? flex;
  final bool center;

  bool get isFixed => width != null;

  static ImportReviewColumn fromKey(String key) {
    return switch (key) {
      ImportConstants.firstNameColumnKey => const ImportReviewColumn(
          key: ImportConstants.firstNameColumnKey,
          label: 'First name',
          flex: 2,
        ),
      ImportConstants.lastNameColumnKey => const ImportReviewColumn(
          key: ImportConstants.lastNameColumnKey,
          label: 'Last name',
          flex: 2,
        ),
      ImportConstants.phoneColumnKey => const ImportReviewColumn(
          key: ImportConstants.phoneColumnKey,
          label: 'Phone',
          width: ImportReviewColumnLayout.phone,
        ),
      ImportConstants.roleColumnKey => const ImportReviewColumn(
          key: ImportConstants.roleColumnKey,
          label: 'Role',
          width: ImportReviewColumnLayout.role,
        ),
      ImportConstants.isTeamLeaderColumnKey => const ImportReviewColumn(
          key: ImportConstants.isTeamLeaderColumnKey,
          label: 'Team Leader',
          width: ImportReviewColumnLayout.teamLeader,
          center: true,
        ),
      ImportConstants.organisationColumnKey => ImportReviewColumn(
          key: ImportConstants.organisationColumnKey,
          label: ImportConstants.headerLabel(ImportConstants.organisationColumnKey),
          flex: 3,
        ),
      ImportConstants.teamNameColumnKey => ImportReviewColumn(
          key: ImportConstants.teamNameColumnKey,
          label: ImportConstants.headerLabel(ImportConstants.teamNameColumnKey),
          flex: 2,
        ),
      ImportConstants.titleColumnKey => ImportReviewColumn(
          key: ImportConstants.titleColumnKey,
          label: ImportConstants.headerLabel(ImportConstants.titleColumnKey),
          flex: 2,
        ),
      ImportConstants.descriptionColumnKey => ImportReviewColumn(
          key: ImportConstants.descriptionColumnKey,
          label: ImportConstants.headerLabel(ImportConstants.descriptionColumnKey),
          flex: 3,
        ),
      _ => ImportReviewColumn(key: key, label: ImportConstants.headerLabel(key), flex: 1),
    };
  }
}

class ImportReviewTable extends StatefulWidget {
  const ImportReviewTable({
    super.key,
    required this.rows,
    required this.columns,
    this.expansionColumns = const <ImportReviewColumn>[],
    this.editable = false,
    this.onToggleExclude,
    this.onView,
    this.onInclude,
    this.onExclude,
  });

  final List<ImportReviewRow> rows;
  final List<ImportReviewColumn> columns;
  final List<ImportReviewColumn> expansionColumns;
  final bool editable;
  final ValueChanged<int>? onToggleExclude;
  final ValueChanged<ImportReviewRow>? onView;
  final ValueChanged<ImportReviewRow>? onInclude;
  final ValueChanged<ImportReviewRow>? onExclude;

  bool get showActions => onView != null || onInclude != null || onExclude != null || editable;

  @override
  State<ImportReviewTable> createState() => _ImportReviewTableState();
}

class _ImportReviewTableState extends State<ImportReviewTable> {
  final Set<int> _expandedRows = <int>{};

  @override
  Widget build(BuildContext context) {
    if (widget.expansionColumns.isEmpty && !widget.editable) return _buildDataTable();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < ImportReviewColumnLayout.compactBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(compact: compact),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: ListView.builder(
                itemCount: widget.rows.length,
                itemBuilder: (BuildContext context, int index) =>
                    _expandableRow(widget.rows[index], compact: compact),
              ),
            ),
          ],
        );
      },
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
                        (ImportReviewColumn c) => DataCell(_cellFor(c, row)),
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
    const TextStyle style = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A));
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 4, 6),
      child: Row(
        children: <Widget>[
          const SizedBox(width: ImportReviewColumnLayout.expand),
          const SizedBox(
            width: ImportReviewColumnLayout.rowNumber,
            child: Text('Row', style: style),
          ),
          if (!compact) ...<Widget>[
            for (final ImportReviewColumn column in widget.columns) ...<Widget>[
              const SizedBox(width: ImportReviewColumnLayout.gap),
              _sized(
                column,
                Text(
                  column.label,
                  style: style,
                  textAlign: column.center ? TextAlign.center : TextAlign.start,
                ),
              ),
            ],
            const SizedBox(width: ImportReviewColumnLayout.gap),
            const SizedBox(
              width: ImportReviewColumnLayout.status,
              child: Text('Status', style: style),
            ),
            if (widget.showActions) ...<Widget>[
              const SizedBox(width: ImportReviewColumnLayout.gap),
              const SizedBox(
                width: ImportReviewColumnLayout.actions,
                child: Text('Action', style: style),
              ),
            ],
          ] else ...<Widget>[
            Expanded(
              child: Text(
                widget.columns.isEmpty ? 'Details' : widget.columns.first.label,
                style: style,
              ),
            ),
            if (widget.showActions) ...<Widget>[
              const SizedBox(width: ImportReviewColumnLayout.gap),
              const SizedBox(
                width: ImportReviewColumnLayout.actions,
                child: Text('Action', style: style, textAlign: TextAlign.end),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sized(ImportReviewColumn column, Widget child) {
    if (column.isFixed) {
      return SizedBox(width: column.width, child: child);
    }
    return Expanded(flex: column.flex ?? 1, child: child);
  }

  Widget _cellFor(ImportReviewColumn column, ImportReviewRow row) {
    if (column.key == ImportConstants.isTeamLeaderColumnKey) {
      return _TeamLeaderMark(isLeader: row.valueFor(column.key).toLowerCase() == 'true');
    }
    if (column.key == ImportConstants.titleColumnKey) {
      return _TruncatedText(text: ImportReviewTitleDisplay.forRow(row, widget.rows));
    }
    return _TruncatedText(
      text: row.valueFor(column.key),
      enableTooltip: column.key != ImportConstants.descriptionColumnKey,
    );
  }

  bool _canExpand(ImportReviewRow row) {
    if (row.metadata['expandable'] == '1') return true;
    return widget.expansionColumns.any((ImportReviewColumn c) => row.valueFor(c.key).isNotEmpty);
  }

  Widget _expandableRow(ImportReviewRow row, {required bool compact}) {
    final bool canExpand = _canExpand(row);
    final bool expanded = canExpand && _expandedRows.contains(row.rowNumber);

    return Opacity(
      opacity: row.excluded ? 0.45 : 1,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: canExpand
                          ? () => setState(() {
                                if (expanded) {
                                  _expandedRows.remove(row.rowNumber);
                                } else {
                                  _expandedRows.add(row.rowNumber);
                                }
                              })
                          : null,
                      child: compact
                          ? _compactCollapsed(row, canExpand: canExpand, expanded: expanded)
                          : _wideCollapsed(row, canExpand: canExpand, expanded: expanded),
                    ),
                  ),
                  if (widget.showActions) ...<Widget>[
                    const SizedBox(width: ImportReviewColumnLayout.gap),
                    _actionsCell(row),
                  ],
                ],
              ),
            ),
            if (expanded) _expansionPanel(row, compact: compact),
          ],
        ),
      ),
    );
  }

  Widget _actionsCell(ImportReviewRow row) {
    if (!widget.showActions) return const SizedBox.shrink();
    final VoidCallback? onToggle = _includeExcludeTap(row);
    final List<Widget> actions = <Widget>[
      if (widget.onView != null)
        MobileRowCardIconAction(
          tooltip: 'View',
          icon: AppIcons.preview,
          onTap: () => widget.onView!(row),
        ),
      if (onToggle != null)
        MobileRowCardIconAction(
          tooltip: row.excluded ? 'Include' : 'Exclude',
          icon: row.excluded ? AppIcons.workflowApproved : AppIcons.remove,
          onTap: onToggle,
          foregroundColor: row.excluded
              ? const Color(0xFF047857)
              : MobileRowCardIconActionMetrics.foregroundColor,
        ),
    ];
    return SizedBox(
      width: ImportReviewColumnLayout.actions,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: spacedMobileRowCardIconActions(actions),
      ),
    );
  }

  VoidCallback? _includeExcludeTap(ImportReviewRow row) {
    if (row.excluded) {
      if (widget.onInclude != null) return () => widget.onInclude!(row);
      if (widget.onToggleExclude != null) return () => widget.onToggleExclude!(row.rowNumber);
      return null;
    }
    if (widget.onExclude != null) return () => widget.onExclude!(row);
    if (widget.onToggleExclude != null) return () => widget.onToggleExclude!(row.rowNumber);
    return null;
  }

  Widget _wideCollapsed(
    ImportReviewRow row, {
    required bool canExpand,
    required bool expanded,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: ImportReviewColumnLayout.expand,
          child: canExpand
              ? Icon(
                  expanded ? AppIcons.expandLess : AppIcons.expandMore,
                  size: 16,
                  color: const Color(0xFF64748B),
                )
              : null,
        ),
        SizedBox(
          width: ImportReviewColumnLayout.rowNumber,
          child: Text(
            '${row.rowNumber}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ),
        for (final ImportReviewColumn column in widget.columns) ...<Widget>[
          const SizedBox(width: ImportReviewColumnLayout.gap),
          _sized(column, _cellFor(column, row)),
        ],
        const SizedBox(width: ImportReviewColumnLayout.gap),
        SizedBox(
          width: ImportReviewColumnLayout.status,
          child: _StatusCell(row: row),
        ),
      ],
    );
  }

  Widget _compactCollapsed(
    ImportReviewRow row, {
    required bool canExpand,
    required bool expanded,
  }) {
    final List<ImportReviewColumn> flexColumns =
        widget.columns.where((ImportReviewColumn c) => !c.isFixed).toList(growable: false);
    final List<ImportReviewColumn> fixedColumns =
        widget.columns.where((ImportReviewColumn c) => c.isFixed).toList(growable: false);
    final bool hasTitle = widget.columns.any((ImportReviewColumn c) => c.key == ImportConstants.titleColumnKey);
    final String title = hasTitle
        ? ImportReviewTitleDisplay.forRow(row, widget.rows)
        : flexColumns
            .map((ImportReviewColumn c) => row.valueFor(c.key))
            .where((String v) => v.isNotEmpty)
            .join(' ');
    final String subtitle = hasTitle
        ? row.valueFor(ImportConstants.descriptionColumnKey)
        : fixedColumns
            .map((ImportReviewColumn c) {
              if (c.key == ImportConstants.isTeamLeaderColumnKey) {
                return row.valueFor(c.key).toLowerCase() == 'true' ? 'Team Leader' : '';
              }
              return row.valueFor(c.key);
            })
            .where((String v) => v.isNotEmpty)
            .join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: ImportReviewColumnLayout.expand,
          child: canExpand
              ? Icon(
                  expanded ? AppIcons.expandLess : AppIcons.expandMore,
                  size: 16,
                  color: const Color(0xFF64748B),
                )
              : null,
        ),
        SizedBox(
          width: ImportReviewColumnLayout.rowNumber,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '${row.rowNumber}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TruncatedText(text: title),
              if (subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 1),
                _TruncatedText(
                  text: subtitle,
                  muted: true,
                  enableTooltip: !hasTitle,
                ),
              ],
              const SizedBox(height: 2),
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
      padding: EdgeInsets.fromLTRB(compact ? 8 : 56, 0, 8, 8),
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
      ImportConstants.titleColumnKey => AppIcons.problems,
      ImportConstants.descriptionColumnKey => AppIcons.info,
      ImportConstants.externalProblemIdColumnKey => AppIcons.key,
      ImportConstants.themeColumnKey => AppIcons.orgType,
      ImportConstants.issuingOrganisationColumnKey => AppIcons.organizations,
      ImportConstants.issuingDepartmentColumnKey => AppIcons.departments,
      ImportConstants.teamNameColumnKey => AppIcons.teams,
      ImportConstants.phoneColumnKey => AppIcons.phone,
      ImportConstants.emailColumnKey => AppIcons.email,
      ImportConstants.organisationColumnKey => AppIcons.organizations,
      ImportConstants.departmentColumnKey => AppIcons.departments,
      ImportConstants.isTeamLeaderColumnKey => AppIcons.users,
      ImportConstants.roleColumnKey => AppIcons.teamMember,
      _ => AppIcons.info,
    };
  }
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

class _TeamLeaderMark extends StatelessWidget {
  const _TeamLeaderMark({required this.isLeader});

  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isLeader ? 'Team Leader' : 'Not Team Leader',
      waitDuration: const Duration(milliseconds: 250),
      child: Align(
        alignment: Alignment.center,
        child: Icon(
          isLeader ? AppIcons.copied : AppIcons.remove,
          size: 16,
          color: isLeader ? const Color(0xFF047857) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _TruncatedText extends StatelessWidget {
  const _TruncatedText({required this.text, this.muted = false, this.enableTooltip = true});

  final String text;
  final bool muted;
  final bool enableTooltip;

  TextStyle get _style => TextStyle(
        fontSize: muted ? 11 : 12,
        fontWeight: muted ? FontWeight.w500 : FontWeight.w600,
        color: muted ? const Color(0xFF64748B) : const Color(0xFF0F172A),
      );

  @override
  Widget build(BuildContext context) {
    final String value = text.trim();
    if (value.isEmpty) {
      return const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)));
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

        if (!overflowed || !enableTooltip) return label;
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
    if (row.excluded) {
      return const Text(
        'Excluded',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
      );
    }
    final Color color = switch (row.severity) {
      ImportRowSeverity.valid => const Color(0xFF047857),
      ImportRowSeverity.warning => const Color(0xFFB45309),
      ImportRowSeverity.error => const Color(0xFFB91C1C),
    };
    final String detail = row.messages.isNotEmpty ? row.messages.join(' · ') : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          row.statusLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
        ),
        if (detail.isNotEmpty)
          Tooltip(
            message: row.messages.join('\n'),
            waitDuration: const Duration(milliseconds: 250),
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
      ],
    );
  }
}
