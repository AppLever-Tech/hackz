import 'package:flutter/material.dart';

import '../../utils/judge_evaluation_service.dart';
import 'judge_evaluation_card.dart';

class PendingEvaluationList extends StatelessWidget {
  const PendingEvaluationList({
    super.key,
    required this.rows,
    required this.onEvaluate,
    required this.onViewDetails,
    required this.onOpenAttachments,
  });

  final List<JudgeEvaluationPendingRow> rows;
  final void Function(JudgeEvaluationPendingRow row) onEvaluate;
  final void Function(JudgeEvaluationPendingRow row) onViewDetails;
  final void Function(JudgeEvaluationPendingRow row) onOpenAttachments;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('No submissions awaiting your evaluation.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = rows[i];
        return JudgeEvaluationCard.pending(
          row: r,
          onEvaluate: () => onEvaluate(r),
          onViewDetails: () => onViewDetails(r),
          onOpenAttachments: () => onOpenAttachments(r),
        );
      },
    );
  }
}
