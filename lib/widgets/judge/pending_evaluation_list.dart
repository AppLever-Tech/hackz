import 'package:flutter/material.dart';

import '../../utils/judge_evaluation_service.dart';
import 'judge_assigned_idea_table.dart';

class PendingEvaluationList extends StatelessWidget {
  const PendingEvaluationList({
    super.key,
    required this.rows,
    required this.onEvaluate,
    required this.onViewDetails,
    required this.onOpenProblem,
  });

  final List<JudgeEvaluationPendingRow> rows;
  final void Function(JudgeEvaluationPendingRow row) onEvaluate;
  final void Function(JudgeEvaluationPendingRow row) onViewDetails;
  final void Function(JudgeEvaluationPendingRow row) onOpenProblem;

  @override
  Widget build(BuildContext context) {
    final List<JudgeAssignedIdeaTableEntry> entries = rows
        .map(
          (JudgeEvaluationPendingRow row) => JudgeAssignedIdeaTableEntry.pending(
            row: row,
            onEvaluate: () => onEvaluate(row),
            onViewDetails: () => onViewDetails(row),
            onOpenProblem: () => onOpenProblem(row),
          ),
        )
        .toList(growable: false);

    return JudgeAssignedIdeaTable(
      entries: entries,
      emptyMessage: 'No submissions awaiting your evaluation.',
    );
  }
}
