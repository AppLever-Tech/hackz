import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/idea_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/judge_evaluation_service.dart';
import 'evaluation_status_pill.dart';

enum JudgeEvaluationCardVariant { pending, evaluated }

class JudgeEvaluationCard extends StatelessWidget {
  const JudgeEvaluationCard.pending({
    super.key,
    required this.row,
    required this.onEvaluate,
    required this.onViewDetails,
    required this.onOpenAttachments,
  })  : variant = JudgeEvaluationCardVariant.pending,
        evaluatedRow = null,
        onViewEvaluation = null,
        onEditEvaluation = null;

  const JudgeEvaluationCard.evaluated({
    super.key,
    required this.evaluatedRow,
    required this.onViewEvaluation,
    required this.onEditEvaluation,
    required this.onViewDetails,
  })  : variant = JudgeEvaluationCardVariant.evaluated,
        row = null,
        onEvaluate = null,
        onOpenAttachments = null;

  final JudgeEvaluationCardVariant variant;
  final JudgeEvaluationPendingRow? row;
  final JudgeEvaluationEvaluatedRow? evaluatedRow;
  final VoidCallback? onEvaluate;
  final VoidCallback? onViewDetails;
  final VoidCallback? onOpenAttachments;
  final VoidCallback? onViewEvaluation;
  final VoidCallback? onEditEvaluation;

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final d = DateTime(due.year, due.month, due.day);
    final n = DateTime(now.year, now.month, now.day);
    final diff = d.difference(n).inDays;
    if (diff < 0) return 'Overdue ${-diff}d';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }

  @override
  Widget build(BuildContext context) {
    if (variant == JudgeEvaluationCardVariant.pending && row != null) {
      return _PendingBody(
        row: row!,
        dueLabel: _dueLabel(row!.reviewDueAt),
        onEvaluate: onEvaluate!,
        onViewDetails: onViewDetails!,
        onOpenAttachments: onOpenAttachments!,
      );
    }
    if (variant == JudgeEvaluationCardVariant.evaluated && evaluatedRow != null) {
      return _EvaluatedBody(
        row: evaluatedRow!,
        onViewEvaluation: onViewEvaluation!,
        onEditEvaluation: onEditEvaluation!,
        onViewDetails: onViewDetails!,
      );
    }
    return const SizedBox.shrink();
  }
}

class _PendingBody extends StatelessWidget {
  const _PendingBody({
    required this.row,
    required this.dueLabel,
    required this.onEvaluate,
    required this.onViewDetails,
    required this.onOpenAttachments,
  });

  final JudgeEvaluationPendingRow row;
  final String dueLabel;
  final VoidCallback onEvaluate;
  final VoidCallback onViewDetails;
  final VoidCallback onOpenAttachments;

  @override
  Widget build(BuildContext context) {
    final idea = row.idea;
    final title = idea.ideaTitle.trim().isNotEmpty ? idea.ideaTitle.trim() : idea.problemNumber;
    final priorityColor = row.priority == JudgeEvaluationPriority.high ? const Color(0xFFB91C1C) : const Color(0xFF64748B);
    final priorityLabel = row.priority == JudgeEvaluationPriority.high ? 'Priority' : 'Standard';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priorityLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: priorityColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                row.problemTitle,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  _miniMeta(AppIcons.users, row.teamName),
                  _miniMeta(AppIcons.clock, formatDateTime(row.submittedAt)),
                  _miniMeta(Icons.flag_outlined, dueLabel),
                  if (row.attachmentCount > 0) _miniMeta(AppIcons.attachments, '${row.attachmentCount} files'),
                ],
              ),
              if (row.category.isNotEmpty || row.theme.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    if (row.category.isNotEmpty) _pill('Category', row.category),
                    if (row.theme.isNotEmpty) _pill('Theme', row.theme),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onEvaluate,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Evaluate'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onViewDetails,
                    child: const Text('Details'),
                  ),
                  const SizedBox(width: 8),
                  if (row.attachmentCount > 0)
                    OutlinedButton.icon(
                      onPressed: onOpenAttachments,
                      icon: const Icon(AppIcons.attachments, size: 16),
                      label: const Text('Files'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class _EvaluatedBody extends StatelessWidget {
  const _EvaluatedBody({
    required this.row,
    required this.onViewEvaluation,
    required this.onEditEvaluation,
    required this.onViewDetails,
  });

  final JudgeEvaluationEvaluatedRow row;
  final VoidCallback onViewEvaluation;
  final VoidCallback onEditEvaluation;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final idea = row.idea;
    final title = idea.ideaTitle.trim().isNotEmpty ? idea.ideaTitle.trim() : idea.problemNumber;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  row.score.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(row.problemTitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(child: Text('Team ${row.teamName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
              EvaluationStatusPill(status: row.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(formatDateTime(row.evaluatedAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              const Spacer(),
              if (row.hasFeedback)
                const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF6366F1))
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              TextButton(onPressed: onViewEvaluation, child: const Text('View evaluation')),
              TextButton(onPressed: onEditEvaluation, child: const Text('Edit')),
              TextButton(onPressed: onViewDetails, child: const Text('Idea details')),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _miniMeta(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _pill(String k, String v) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$k: $v',
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4338CA)),
    ),
  );
}
