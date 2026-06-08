import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../utils/judge_evaluation_service.dart';

/// Compact status pill for judge assigned-idea tables.
class JudgeAssignmentRowStatusPill extends StatelessWidget {
  const JudgeAssignmentRowStatusPill({
    super.key,
    required this.status,
    this.compact = true,
  });

  final JudgeAssignmentRowStatus status;
  final bool compact;

  static Color colorFor(JudgeAssignmentRowStatus status) {
    return switch (status) {
      JudgeAssignmentRowStatus.assigned => const Color(0xFF6366F1),
      JudgeAssignmentRowStatus.inProgress => const Color(0xFFEA580C),
      JudgeAssignmentRowStatus.completed => const Color(0xFF059669),
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color color = colorFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// Muted meta line under workspace pills (team, date, due, judges, attachments).
class JudgeAssignedIdeaMetaLine extends StatelessWidget {
  const JudgeAssignedIdeaMetaLine({
    super.key,
    required this.teamName,
    required this.dateLabel,
    this.dueLabel,
    this.assignedJudgeCount,
    this.attachmentCount = 0,
  });

  final String teamName;
  final String dateLabel;
  final String? dueLabel;
  final int? assignedJudgeCount;
  final int attachmentCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _miniMeta(AppIcons.teams, teamName.trim().isEmpty ? 'Team' : teamName.trim()),
        _miniMeta(AppIcons.clock, dateLabel),
        if (dueLabel != null && dueLabel!.trim().isNotEmpty)
          _miniMeta(AppIcons.clock, dueLabel!.trim()),
        if (assignedJudgeCount != null && assignedJudgeCount! > 0)
          _miniMeta(
            AppIcons.judges,
            '${assignedJudgeCount!} judge${assignedJudgeCount == 1 ? '' : 's'} assigned',
          ),
        if (attachmentCount > 0)
          _miniMeta(
            AppIcons.attachments,
            '$attachmentCount file${attachmentCount == 1 ? '' : 's'}',
          ),
      ],
    );
  }
}

Widget _miniMeta(IconData icon, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppSemanticColors.statusText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
