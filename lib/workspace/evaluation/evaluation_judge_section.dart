import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/common_helpers.dart';
import '../../widgets/common/context_pill.dart';
import '../../widgets/common/context_pill_theme.dart';
import '../../features/user/workspace/user_workspace.dart';
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
                child: judge.judgeId.trim().isNotEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: ContextPill(
                          label: judge.judgeName,
                          semantic: ContextPillSemantic.judge,
                          onTap: () => UserWorkspace.push(context, judge.judgeId),
                          compact: true,
                        ),
                      )
                    : Text(
                        judge.judgeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                      ),
              ),
              Text(
                '${judge.overallScore.toStringAsFixed(1)} / ${vm.scoringScale}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Evaluated ${formatDateTime(judge.evaluatedAt)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
          ),
          if (judge.criteria.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final EvaluationCriterionScore c in judge.criteria)
                  _miniChip(c.label, c.value, c.maxValue),
              ],
            ),
          ],
          if (judge.criterionComments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            for (final MapEntry<String, String> e in judge.criterionComments.entries)
              _commentLine(judge, e.key, e.value),
          ],
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

  static Widget _miniChip(String label, double value, int max) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}/$max',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4338CA)),
      ),
    );
  }

  static Widget _commentLine(EvaluationJudgeEntry judge, String criterionId, String comment) {
    String label = criterionId;
    for (final EvaluationCriterionScore c in judge.criteria) {
      if (c.criterionId == criterionId) {
        label = c.label;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, height: 1.35, color: Color(0xFF475569)),
          children: <InlineSpan>[
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334155))),
            TextSpan(text: comment.trim()),
          ],
        ),
      ),
    );
  }
}
