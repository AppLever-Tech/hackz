import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/common_helpers.dart';
import 'evaluation_workspace.dart';
import 'evaluation_workspace_loader.dart';

class EvaluationJudgeSection extends StatelessWidget {
  const EvaluationJudgeSection({super.key, required this.vm});

  final EvaluationWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(AppIcons.judges, size: 18, color: Color(0xFF4A67FF)),
            const SizedBox(width: 8),
            Text(
              vm.scope == EvaluationWorkspaceScope.ideaAggregate ? 'Judge summaries' : 'Judge summary',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...vm.judgeEntries.map((EvaluationJudgeEntry j) => _judgeTile(context, j)),
      ],
    );
  }

  Widget _judgeTile(BuildContext context, EvaluationJudgeEntry judge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: InkWell(
                  onTap: judge.judgeId.trim().isEmpty
                      ? null
                      : () => EvaluationWorkspace.openUserFromEvaluation(context, judge.judgeId),
                  child: Text(
                    judge.judgeName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                  ),
                ),
              ),
              Text(
                '${judge.overallScore.toStringAsFixed(1)} / 10',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Evaluated ${formatDateTime(judge.evaluatedAt)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _miniChip('Innovation', judge.innovation),
              _miniChip('Feasibility', judge.feasibility),
              _miniChip('Impact', judge.impact),
            ],
          ),
          if (judge.remarks.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              judge.remarks.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _miniChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $value/10',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4338CA)),
      ),
    );
  }
}
