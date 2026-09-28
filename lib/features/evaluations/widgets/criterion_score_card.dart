import 'package:flutter/material.dart';

import 'judge_score_grid.dart';
import '../models/evaluation_criterion.dart';

/// Compact, responsive scoring card for one [EvaluationCriterion].
///
/// Layout:
///   ┌───────────────────────────────────────────────────────────┐
///   │ Innovation                                    20% • opt.  │
///   │ Originality and novelty of the approach                   │
///   │  [1][2][3][4][5][6][7][8][9][10]                          │
///   │ [_Optional comment____________________________________ ]  │
///   └───────────────────────────────────────────────────────────┘
///
/// The score selector wraps onto multiple rows automatically when there's
/// not enough horizontal space — ensures large criteria counts work on
/// narrow phones without overflow.
class CriterionScoreCard extends StatelessWidget {
  const CriterionScoreCard({
    super.key,
    required this.criterion,
    required this.value,
    required this.onChanged,
    required this.weightLabel,
    this.readOnly = false,
    this.comment,
    this.onCommentChanged,
    this.ownershipBadge,
  });

  final EvaluationCriterion criterion;

  /// Currently selected score or `null` when un-scored.
  final int? value;

  final ValueChanged<int> onChanged;

  /// Pre-formatted weight label (e.g. `20%`). The card doesn't compute this
  /// because normalization may be context-specific.
  final String weightLabel;

  final bool readOnly;

  /// Current comment text. Only rendered when `criterion.commentsEnabled`
  /// is true.
  final String? comment;

  final ValueChanged<String>? onCommentChanged;
  final String? ownershipBadge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final int safeValue = value ?? criterion.minScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  criterion.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  weightLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4338CA),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(width: 6),
                Text(
                  '$safeValue/${criterion.maxScore}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
              if ((ownershipBadge ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    ownershipBadge!.trim(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if ((criterion.description ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              criterion.description!.trim(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          JudgeScoreGrid(
            label: criterion.title,
            selectedValue: safeValue,
            onChanged: onChanged,
            minValue: criterion.minScore,
            maxValue: criterion.maxScore,
            compact: true,
            readOnly: readOnly,
            showLabel: false,
          ),
          if (criterion.commentsEnabled && onCommentChanged != null) ...<Widget>[
            const SizedBox(height: 8),
            TextFormField(
              initialValue: comment ?? '',
              enabled: !readOnly,
              maxLines: 2,
              minLines: 1,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Optional comment…',
                hintStyle: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: onCommentChanged,
            ),
          ],
        ],
      ),
    );
  }
}
