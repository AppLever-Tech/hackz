import 'package:flutter/material.dart';

import '../../../../constants/status_styles.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../../screens/common/dashboard_components.dart';
import '../../../../utils/common_helpers.dart';
import '../../workspace/problem_workspace_loader.dart';

/// Ideas table styled like [ProblemStatementsTableScreen].
class SubmittedIdeasTable extends StatelessWidget {
  const SubmittedIdeasTable({
    super.key,
    required this.ideas,
    required this.onOpenIdea,
  });

  final List<ProblemIdeaPreview> ideas;
  final ValueChanged<ProblemIdeaPreview> onOpenIdea;

  static const List<_IdeasTableColumn> _columns = <_IdeasTableColumn>[
    _IdeasTableColumn(label: 'Title', flex: 10, minWidth: 200),
    _IdeasTableColumn(label: 'Submitted by', flex: 4, minWidth: 120),
    _IdeasTableColumn(label: 'Status', flex: 3, minWidth: 108),
    _IdeasTableColumn(label: 'Score', flex: 2, minWidth: 72, align: TextAlign.center),
    _IdeasTableColumn(label: 'Submitted', flex: 3, minWidth: 108),
    _IdeasTableColumn(label: 'Actions', flex: 2, minWidth: 56, align: TextAlign.end),
  ];

  @override
  Widget build(BuildContext context) {
    final double minWidth = _columns.fold<double>(0, (sum, c) => sum + c.minWidth) + 32;

    return DecoratedBox(
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool needsHorizontalScroll =
                constraints.maxWidth.isFinite && constraints.maxWidth < minWidth;

            final Widget table = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _IdeasTableHeaderRow(columns: _columns),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: ideas.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ProblemIdeaPreview preview = ideas[index];
                      return _IdeasTableDataRow(
                        preview: preview,
                        columns: _columns,
                        striped: index.isOdd,
                        onOpen: () => onOpenIdea(preview),
                      );
                    },
                  ),
                ),
              ],
            );

            if (!needsHorizontalScroll) {
              return table;
            }

            return Scrollbar(
              thumbVisibility: true,
              notificationPredicate: (ScrollNotification notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: minWidth, child: table),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IdeasTableColumn {
  const _IdeasTableColumn({
    required this.label,
    required this.flex,
    required this.minWidth,
    this.align = TextAlign.start,
  });

  final String label;
  final int flex;
  final double minWidth;
  final TextAlign align;
}

class _IdeasTableHeaderRow extends StatelessWidget {
  const _IdeasTableHeaderRow({required this.columns});

  final List<_IdeasTableColumn> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF5F3FF), Color(0xFFEEF4FF)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: columns
            .map(
              (col) => Expanded(
                flex: col.flex,
                child: Text(
                  col.label.toUpperCase(),
                  textAlign: col.align,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _IdeasTableDataRow extends StatelessWidget {
  const _IdeasTableDataRow({
    required this.preview,
    required this.columns,
    required this.striped,
    required this.onOpen,
  });

  final ProblemIdeaPreview preview;
  final List<_IdeasTableColumn> columns;
  final bool striped;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final idea = preview.idea;
    final String title = idea.ideaTitle.trim().isEmpty ? 'Untitled idea' : idea.ideaTitle.trim();
    final String submittedBy =
        preview.createdByName.trim().isEmpty ? 'Unknown' : preview.createdByName.trim();
    final String score = preview.avgScore == null ? '—' : preview.avgScore!.toStringAsFixed(1);
    final String submittedAt = formatDateTime(idea.createdAt);

    return Material(
      color: striped ? const Color(0xFFF8FAFC) : const Color(0xFFFCFDFF),
      child: InkWell(
        onTap: onOpen,
        hoverColor: const Color(0xFFF1F5FF),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEF2F7))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: columns[0].flex,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                    height: 1.35,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0x334F46E5),
                  ),
                ),
              ),
              Expanded(
                flex: columns[1].flex,
                child: Text(
                  submittedBy,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
              Expanded(
                flex: columns[2].flex,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _IdeaStatusPill(status: idea.status),
                ),
              ),
              Expanded(
                flex: columns[3].flex,
                child: Text(
                  score,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                flex: columns[4].flex,
                child: Text(
                  submittedAt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
              Expanded(
                flex: columns[5].flex,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _IdeasTableIconButton(
                    tooltip: 'Open idea',
                    icon: Icons.open_in_new_rounded,
                    onPressed: onOpen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaStatusPill extends StatelessWidget {
  const _IdeaStatusPill({required this.status});

  final IdeaStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = StatusStyles.colorForIdeaStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        StatusStyles.labelForIdeaStatus(status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _IdeasTableIconButton extends StatelessWidget {
  const _IdeasTableIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF475569)),
        ),
      ),
    );
  }
}
