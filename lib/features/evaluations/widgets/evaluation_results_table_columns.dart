import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../../../widgets/data_view/data_table_column.dart';
import '../services/evaluation_ranking_service.dart';

class EvaluationResultsTableActions {
  const EvaluationResultsTableActions({
    required this.onOpenIdea,
    required this.onShortlist,
    required this.onReject,
  });

  final void Function(EvaluationResultsRow row) onOpenIdea;
  final void Function(EvaluationResultsRow row) onShortlist;
  final void Function(EvaluationResultsRow row) onReject;
}

abstract final class EvaluationResultsTableColumns {
  EvaluationResultsTableColumns._();

  static List<DataTableColumn<EvaluationResultsRow>> build({
    required EvaluationResultsTableActions actions,
  }) {
    return <DataTableColumn<EvaluationResultsRow>>[
      DataTableColumn<EvaluationResultsRow>(
        label: 'Rank',
        flex: 1,
        minWidth: 52,
        align: Alignment.center,
        cell: (_, EvaluationResultsRow row) => Center(
          child: Text(
            row.rank > 0 ? '${row.rank}' : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
          ),
        ),
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Idea',
        flex: 4,
        minWidth: 140,
        cell: (BuildContext context, EvaluationResultsRow row) {
          final String title = row.idea.ideaTitle.trim().isEmpty ? row.idea.ideaId : row.idea.ideaTitle.trim();
          return InkWell(
            onTap: () => actions.onOpenIdea(row),
            borderRadius: BorderRadius.circular(4),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
            ),
          );
        },
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Problem',
        flex: 3,
        minWidth: 120,
        cell: (_, EvaluationResultsRow row) => Text(
          row.problemTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Average',
        flex: 1,
        minWidth: 72,
        align: Alignment.center,
        sortKey: 'average',
        cell: (_, EvaluationResultsRow row) => Center(
          child: _ScoreText(value: row.aggregate.averageScore, emphasized: true),
        ),
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Highest',
        flex: 1,
        minWidth: 68,
        align: Alignment.center,
        sortKey: 'highest',
        cell: (_, EvaluationResultsRow row) => Center(
          child: _ScoreText(value: row.aggregate.highestScore),
        ),
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Lowest',
        flex: 1,
        minWidth: 68,
        align: Alignment.center,
        sortKey: 'lowest',
        cell: (_, EvaluationResultsRow row) => Center(
          child: _ScoreText(value: row.aggregate.lowestScore),
        ),
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Evaluators',
        flex: 1,
        minWidth: 72,
        align: Alignment.center,
        cell: (_, EvaluationResultsRow row) => Center(
          child: Text(
            '${row.aggregate.totalEvaluators}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ),
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Status',
        flex: 2,
        minWidth: 110,
        align: Alignment.center,
        sortKey: 'status',
        cell: (_, EvaluationResultsRow row) => Center(
          child: _StatusCell(status: row.idea.status),
        ),
      ),
      DataTableColumn<EvaluationResultsRow>(
        label: 'Actions',
        flex: 3,
        minWidth: 140,
        align: Alignment.centerLeft,
        cell: (BuildContext context, EvaluationResultsRow row) => _ActionsCell(
          row: row,
          actions: actions,
        ),
      ),
    ];
  }
}

/// Compact premium card for mobile evaluation results.
class EvaluationResultsRowCard extends StatelessWidget {
  const EvaluationResultsRowCard({
    super.key,
    required this.row,
    required this.actions,
  });

  final EvaluationResultsRow row;
  final EvaluationResultsTableActions actions;

  @override
  Widget build(BuildContext context) {
    final String title = row.idea.ideaTitle.trim().isEmpty ? row.idea.ideaId : row.idea.ideaTitle.trim();
    final bool canAct = row.idea.status == IdeaStatus.evaluated;
    final Color statusColor = IdeaStatusHelpers.color(row.idea.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A38FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  row.rank > 0 ? '#${row.rank}' : '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF6A38FF)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: () => actions.onOpenIdea(row),
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: MobileRowCardStyles.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.problemTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _MetricChip(label: 'Avg', value: row.aggregate.averageScore, accent: true),
              _MetricChip(label: 'High', value: row.aggregate.highestScore),
              _MetricChip(label: 'Low', value: row.aggregate.lowestScore),
              _MetricChip(label: 'Judges', value: row.aggregate.totalEvaluators.toDouble(), isCount: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(IdeaStatusHelpers.icon(row.idea.status), size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      IdeaStatusHelpers.label(row.idea.status),
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canAct) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ProblemWorkflowActionPill(
                  label: 'Shortlist',
                  icon: AppIcons.statusShortlisted,
                  semantic: ProblemWorkflowPillSemantic.primary,
                  onTap: () => actions.onShortlist(row),
                ),
                ProblemWorkflowActionPill(
                  label: 'Reject',
                  icon: AppIcons.statusRejected,
                  semantic: ProblemWorkflowPillSemantic.pending,
                  onTap: () => actions.onReject(row),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.accent = false,
    this.isCount = false,
  });

  final String label;
  final double? value;
  final bool accent;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    final String display = value == null
        ? '—'
        : isCount
            ? value!.toInt().toString()
            : value!.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent ? const Color(0xFFE9D5FF) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: accent ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            display,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: accent ? const Color(0xFF6A38FF) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreText extends StatelessWidget {
  const _ScoreText({required this.value, this.emphasized = false});

  final double? value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final String text = value == null ? '—' : value!.toStringAsFixed(1);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: emphasized ? 13 : 12.5,
        fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
        color: emphasized ? const Color(0xFF6A38FF) : const Color(0xFF334155),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.status});

  final IdeaStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = IdeaStatusHelpers.color(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(IdeaStatusHelpers.icon(status), size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            IdeaStatusHelpers.label(status),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }
}

class _ActionsCell extends StatelessWidget {
  const _ActionsCell({
    required this.row,
    required this.actions,
  });

  final EvaluationResultsRow row;
  final EvaluationResultsTableActions actions;

  @override
  Widget build(BuildContext context) {
    if (row.idea.status != IdeaStatus.evaluated) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ProblemWorkflowActionPill(
          label: 'Shortlist',
          icon: AppIcons.statusShortlisted,
          semantic: ProblemWorkflowPillSemantic.primary,
          onTap: () => actions.onShortlist(row),
        ),
        ProblemWorkflowActionPill(
          label: 'Reject',
          icon: AppIcons.statusRejected,
          semantic: ProblemWorkflowPillSemantic.pending,
          onTap: () => actions.onReject(row),
        ),
      ],
    );
  }
}
