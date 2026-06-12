import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../models/evaluation_details_view_model.dart';
import 'evaluation_result_card.dart';

/// Judge evaluation list with total count in header.
class EvaluationJudgeBreakdownPanel extends StatelessWidget {
  const EvaluationJudgeBreakdownPanel({
    super.key,
    required this.judgeDetails,
    required this.departmentCode,
    this.compactRows = false,
  });

  final List<EvaluationJudgeDetail> judgeDetails;
  final String departmentCode;
  final bool compactRows;

  @override
  Widget build(BuildContext context) {
    final String countLabel = judgeDetails.isEmpty
        ? '0 Judges'
        : '${judgeDetails.length} Judge${judgeDetails.length == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(AppIcons.judges, size: 18, color: Color(0xFF4A67FF)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Judge Evaluation Breakdown',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ),
              Text(
                countLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'How each evaluator scored this idea.',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 10),
          if (judgeDetails.isEmpty)
            const Text(
              'No judge evaluations recorded yet.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            )
          else
            for (int i = 0; i < judgeDetails.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 8),
              EvaluationResultCard(
                detail: judgeDetails[i],
                departmentCode: departmentCode,
                compact: compactRows,
              ),
            ],
        ],
      ),
    );
  }
}
