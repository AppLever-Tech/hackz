import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/common_helpers.dart';
import '../../utils/judge_evaluation_service.dart';
import '../common/card_overflow_menu.dart';
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

  void _onMenuSelected(String value) {
    switch (value) {
      case 'evaluate':
        onEvaluate();
      case 'details':
        onViewDetails();
      case 'files':
        onOpenAttachments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final idea = row.idea;
    final title = idea.ideaTitle.trim().isNotEmpty ? idea.ideaTitle.trim() : idea.problemNumber;
    final priorityColor = row.priority == JudgeEvaluationPriority.high ? const Color(0xFFB91C1C) : const Color(0xFF64748B);
    final priorityLabel = row.priority == JudgeEvaluationPriority.high ? 'Priority' : 'Standard';
    final hasFiles = row.attachmentCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: _ideaTitleText(title)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: priorityColor),
                ),
              ),
              const SizedBox(width: 4),
              CardOverflowMenuButton(
                tooltip: 'Idea actions',
                onSelected: _onMenuSelected,
                actions: <CardOverflowMenuAction>[
                  const CardOverflowMenuAction(value: 'evaluate', icon: AppIcons.scoring, label: 'Evaluate'),
                  const CardOverflowMenuAction(value: 'details', icon: AppIcons.preview, label: 'Details'),
                  CardOverflowMenuAction(
                    value: 'files',
                    icon: AppIcons.attachmentDocument,
                    label: 'Files',
                    enabled: hasFiles,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          _iconLine(AppIcons.problems, row.problemTitle, dense: true),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: <Widget>[
              _miniMeta(AppIcons.teams, row.teamName, dense: true),
              _miniMeta(AppIcons.clock, formatDateTime(row.submittedAt), dense: true),
              _miniMeta(AppIcons.statusUnderReview, dueLabel, dense: true),
              if (hasFiles) _miniMeta(AppIcons.attachments, '${row.attachmentCount} files', dense: true),
            ],
          ),
          if (row.category.isNotEmpty || row.theme.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: <Widget>[
                if (row.category.isNotEmpty) _pill(AppIcons.orgType, row.category),
                if (row.theme.isNotEmpty) _pill(AppIcons.address, row.theme),
              ],
            ),
          ],
        ],
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

  void _onMenuSelected(String value) {
    switch (value) {
      case 'view':
        onViewEvaluation();
      case 'edit':
        onEditEvaluation();
      case 'details':
        onViewDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final idea = row.idea;
    final title = idea.ideaTitle.trim().isNotEmpty ? idea.ideaTitle.trim() : idea.problemNumber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(child: _ideaTitleText(title)),
              const SizedBox(width: 6),
              EvaluationStatusPill(status: row.status, compact: true),
              const SizedBox(width: 4),
              _scorePill(row.score),
              const SizedBox(width: 4),
              CardOverflowMenuButton(
                tooltip: 'Idea actions',
                onSelected: _onMenuSelected,
                actions: const <CardOverflowMenuAction>[
                  CardOverflowMenuAction(value: 'view', icon: AppIcons.preview, label: 'View evaluation'),
                  CardOverflowMenuAction(value: 'edit', icon: AppIcons.edit, label: 'Edit'),
                  CardOverflowMenuAction(value: 'details', icon: AppIcons.ideas, label: 'Idea details'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          _iconLine(AppIcons.problems, row.problemTitle, dense: true),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(child: _miniMeta(AppIcons.teams, row.teamName, dense: true)),
              const SizedBox(width: 8),
              _miniMeta(AppIcons.clock, formatDateTime(row.evaluatedAt), dense: true),
              if (row.hasFeedback) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(AppIcons.helpSupport, size: 13, color: Color(0xFF6366F1)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Widget _ideaTitleText(String title) {
  return Row(
    children: <Widget>[
      const Icon(AppIcons.ideas, size: 16, color: Color(0xFF6366F1)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _scorePill(double score) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(AppIcons.scoring, size: 12, color: Color(0xFF15803D)),
        const SizedBox(width: 3),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
        ),
      ],
    ),
  );
}

Widget _iconLine(IconData icon, String text, {bool dense = false}) {
  final iconSize = dense ? 12.0 : 14.0;
  final fontSize = dense ? 11.0 : 12.0;
  return Row(
    children: <Widget>[
      Icon(icon, size: iconSize, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _miniMeta(IconData icon, String text, {bool dense = false}) {
  final iconSize = dense ? 12.0 : 14.0;
  final fontSize = dense ? 10.0 : 11.0;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: iconSize, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _pill(IconData icon, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: const Color(0xFF4338CA)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4338CA)),
        ),
      ],
    ),
  );
}
