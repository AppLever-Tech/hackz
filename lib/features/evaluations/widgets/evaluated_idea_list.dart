import 'package:flutter/material.dart';

import '../services/judge_evaluation_service.dart';
import 'judge_assigned_idea_table.dart';

class EvaluatedIdeaList extends StatelessWidget {
  const EvaluatedIdeaList({
    super.key,
    required this.rows,
    required this.onViewEvaluation,
    required this.onViewDetails,
    required this.onOpenProblem,
  });

  final List<JudgeEvaluationEvaluatedRow> rows;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewEvaluation;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewDetails;
  final void Function(JudgeEvaluationEvaluatedRow row) onOpenProblem;

  @override
  Widget build(BuildContext context) {
    final List<JudgeAssignedIdeaTableEntry> entries = rows
        .map(
          (JudgeEvaluationEvaluatedRow row) => JudgeAssignedIdeaTableEntry.evaluated(
            row: row,
            onReview: () => onViewEvaluation(row),
            onViewDetails: () => onViewDetails(row),
            onOpenProblem: () => onOpenProblem(row),
          ),
        )
        .toList(growable: false);

    return JudgeAssignedIdeaTable(
      entries: entries,
      emptyMessage: 'You have not submitted evaluations yet.',
    );
  }
}
