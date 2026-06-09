import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/score_model.dart';
import '../services/judge_evaluation_feedback_codec.dart';
import '../widgets/evaluate_idea_dialog.dart';
import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';
import '../services/evaluation_template_helpers.dart';
import 'criterion_score_card.dart';

/// Read-only evaluation template breakdown — same [CriterionScoreCard] as judge dialog.
class EvaluationCriterionReadonlyView extends StatelessWidget {
  const EvaluationCriterionReadonlyView({
    super.key,
    required this.score,
    required this.template,
  });

  final ScoreModel score;
  final EvaluationTemplate template;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Map<String, int> scores = _resolvedScores();
    final String remarks = JudgeEvaluationFeedbackCodec.displayRemarks(score.feedback);
    final double overall = template.computeOverall(
      scores.map((String k, int v) => MapEntry<String, double>(k, v.toDouble())),
    );
    final Color accent = JudgeScoreGridHueLookup.forOverall(overall, template.scoringScale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[accent.withValues(alpha: 0.14), accent.withValues(alpha: 0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: <Widget>[
              Icon(AppIcons.insights, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Overall Score',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF334155)),
                ),
              ),
              Text(
                overall.toStringAsFixed(1),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: accent, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '/ ${template.scoringScale}',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final EvaluationCriterion c in template.orderedCriteria)
          if (scores.containsKey(c.criterionId))
            CriterionScoreCard(
              criterion: c,
              value: scores[c.criterionId],
              readOnly: true,
              onChanged: (_) {},
              weightLabel: EvaluationTemplateHelpers.weightLabel(c, template),
              ownershipBadge: c.sourceType == EvaluationCriterionSourceType.department
                  ? 'Department specific'
                  : null,
              comment: score.criteriaComments[c.criterionId],
              onCommentChanged: c.commentsEnabled &&
                      (score.criteriaComments[c.criterionId]?.trim().isNotEmpty ?? false)
                  ? (_) {}
                  : null,
            ),
        if (remarks.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            'Overall feedback',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              remarks.trim(),
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF475569), height: 1.4),
            ),
          ),
        ],
      ],
    );
  }

  Map<String, int> _resolvedScores() {
    final Map<String, int> out = <String, int>{};
    final JudgeEvaluationDecodedFeedback? legacy = JudgeEvaluationFeedbackCodec.tryDecode(score.feedback);

    for (final EvaluationCriterion c in template.orderedCriteria) {
      final double? saved = score.criteriaScores[c.criterionId];
      if (saved != null) {
        out[c.criterionId] = saved.round().clamp(c.minScore, c.maxScore);
        continue;
      }
      if (legacy != null) {
        int? seed;
        switch (c.criterionId) {
          case 'innovation':
            seed = legacy.innovation;
            break;
          case 'feasibility':
            seed = legacy.feasibility;
            break;
          case 'impact':
            seed = legacy.impact;
            break;
        }
        if (seed != null) {
          out[c.criterionId] = seed.clamp(c.minScore, c.maxScore);
        }
      }
    }
    return out;
  }
}
