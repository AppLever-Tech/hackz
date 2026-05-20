import 'package:flutter/material.dart';

import '../../utils/judge_evaluation_service.dart';
import 'judge_evaluation_card.dart';

class EvaluatedIdeaList extends StatelessWidget {
  const EvaluatedIdeaList({
    super.key,
    required this.rows,
    required this.onViewEvaluation,
    required this.onEditEvaluation,
    required this.onViewDetails,
    required this.onOpenProblem,
  });

  final List<JudgeEvaluationEvaluatedRow> rows;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewEvaluation;
  final void Function(JudgeEvaluationEvaluatedRow row) onEditEvaluation;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewDetails;
  final void Function(JudgeEvaluationEvaluatedRow row) onOpenProblem;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('You have not submitted evaluations yet.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = rows[i];
        return JudgeEvaluationCard.evaluated(
          evaluatedRow: r,
          onViewEvaluation: () => onViewEvaluation(r),
          onEditEvaluation: () => onEditEvaluation(r),
          onViewDetails: () => onViewDetails(r),
          onOpenProblem: () => onOpenProblem(r),
        );
      },
    );
  }
}
