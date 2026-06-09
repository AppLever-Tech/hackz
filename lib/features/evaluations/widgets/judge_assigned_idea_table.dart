import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../utils/common_helpers.dart';
import '../services/judge_evaluation_service.dart';
import '../../../widgets/common/context_pill_theme.dart';
import '../../../widgets/common/entity_card_pills.dart';
import 'judge_assignment_row_status.dart';

/// Normalized row model for the judge assigned-ideas table.
class JudgeAssignedIdeaTableEntry {
  const JudgeAssignedIdeaTableEntry({
    required this.ideaId,
    required this.ideaTitle,
    required this.problemLabel,
    required this.teamName,
    required this.attachmentCount,
    required this.dateLabel,
    this.dueLabel,
    required this.assignedJudgeCount,
    required this.workflowStatus,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.onOpenIdea,
    required this.onOpenProblem,
  });

  factory JudgeAssignedIdeaTableEntry.pending({
    required JudgeEvaluationPendingRow row,
    required VoidCallback onEvaluate,
    required VoidCallback onViewDetails,
    required VoidCallback onOpenProblem,
  }) {
    return JudgeAssignedIdeaTableEntry(
      ideaId: row.ideaId,
      ideaTitle: _ideaTitle(row.idea),
      problemLabel: row.problemTitle.trim().isEmpty ? 'Problem' : row.problemTitle.trim(),
      teamName: row.teamName,
      attachmentCount: row.attachmentCount,
      dateLabel: formatDateTime(row.submittedAt),
      dueLabel: _dueLabel(row.reviewDueAt),
      assignedJudgeCount: row.assignedJudgeCount,
      workflowStatus: row.workflowStatus,
      primaryActionLabel: 'Evaluate',
      onPrimaryAction: onEvaluate,
      onOpenIdea: onViewDetails,
      onOpenProblem: onOpenProblem,
    );
  }

  factory JudgeAssignedIdeaTableEntry.evaluated({
    required JudgeEvaluationEvaluatedRow row,
    required VoidCallback onReview,
    required VoidCallback onViewDetails,
    required VoidCallback onOpenProblem,
  }) {
    return JudgeAssignedIdeaTableEntry(
      ideaId: row.ideaId,
      ideaTitle: _ideaTitle(row.idea),
      problemLabel: row.problemTitle.trim().isEmpty ? 'Problem' : row.problemTitle.trim(),
      teamName: row.teamName,
      attachmentCount: 0,
      dateLabel: formatDateTime(row.evaluatedAt),
      assignedJudgeCount: row.assignedJudgeCount,
      workflowStatus: row.workflowStatus,
      primaryActionLabel: 'Review',
      onPrimaryAction: onReview,
      onOpenIdea: onViewDetails,
      onOpenProblem: onOpenProblem,
    );
  }

  final String ideaId;
  final String ideaTitle;
  final String problemLabel;
  final String teamName;
  final int attachmentCount;
  final String dateLabel;
  final String? dueLabel;
  final int assignedJudgeCount;
  final JudgeAssignmentRowStatus workflowStatus;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpenIdea;
  final VoidCallback onOpenProblem;

  static String _ideaTitle(IdeaModel idea) {
    final String title = idea.ideaTitle.trim();
    if (title.isNotEmpty) return title;
    if (idea.problemNumber.trim().isNotEmpty) return idea.problemNumber.trim();
    return 'Untitled idea';
  }

  static String _dueLabel(DateTime due) {
    final DateTime now = DateTime.now();
    final DateTime d = DateTime(due.year, due.month, due.day);
    final DateTime n = DateTime(now.year, now.month, now.day);
    final int diff = d.difference(n).inDays;
    if (diff < 0) return 'Overdue ${-diff}d';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }
}

/// Premium responsive table for judge assigned ideas (virtualised, no cards).
class JudgeAssignedIdeaTable extends StatelessWidget {
  const JudgeAssignedIdeaTable({
    super.key,
    required this.entries,
    this.emptyMessage = 'No assigned ideas found.',
  });

  final List<JudgeAssignedIdeaTableEntry> entries;
  final String emptyMessage;

  static const Color _headerBg = Color(0xFFF1F4FB);
  static const Color _border = Color(0xFFE3E8F4);
  static const Color _altRowBg = Color(0xFFFAFBFE);
  static const Color _headerText = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stacked =
            ResponsiveHelper.isMobile(context) || constraints.maxWidth < 720;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(stacked: stacked),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, thickness: 1, color: _border),
                  itemBuilder: (BuildContext context, int index) {
                    final JudgeAssignedIdeaTableEntry entry = entries[index];
                    final Color rowBg = index.isEven ? Colors.white : _altRowBg;
                    return ColoredBox(
                      color: rowBg,
                      child: stacked ? _StackedRow(entry: entry) : _WideRow(entry: entry),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool stacked}) {
    return Container(
      decoration: const BoxDecoration(
        color: _headerBg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: stacked
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Assigned ideas',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _headerText,
                ),
              ),
            )
          : const Row(
              children: <Widget>[
                Expanded(
                  flex: 8,
                  child: Text(
                    'Idea',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _headerText,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 108,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _headerText,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: Text(
                    'Action',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _headerText,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _IdeaPrimaryCell extends StatelessWidget {
  const _IdeaPrimaryCell({
    required this.entry,
    required this.compact,
  });

  final JudgeAssignedIdeaTableEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        EntityCardPills.workspace(
          entry.ideaTitle,
          ContextPillSemantic.idea,
          entry.onOpenIdea,
          icon: AppIcons.ideas,
        ),
        SizedBox(height: compact ? 6 : 8),
        EntityCardPills.workspace(
          entry.problemLabel,
          ContextPillSemantic.problem,
          entry.onOpenProblem,
          icon: AppIcons.problems,
        ),
        const SizedBox(height: 6),
        JudgeAssignedIdeaMetaLine(
          teamName: entry.teamName,
          dateLabel: entry.dateLabel,
          dueLabel: entry.dueLabel,
          assignedJudgeCount: entry.assignedJudgeCount,
          attachmentCount: entry.attachmentCount,
        ),
      ],
    );
  }
}

class _WideRow extends StatelessWidget {
  const _WideRow({required this.entry});

  final JudgeAssignedIdeaTableEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 8,
            child: _IdeaPrimaryCell(entry: entry, compact: false),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 108,
            child: Align(
              alignment: Alignment.centerLeft,
              child: JudgeAssignmentRowStatusPill(status: entry.workflowStatus),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ActionCell(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedRow extends StatelessWidget {
  const _StackedRow({required this.entry});

  final JudgeAssignedIdeaTableEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _IdeaPrimaryCell(entry: entry, compact: true),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              JudgeAssignmentRowStatusPill(status: entry.workflowStatus),
              const Spacer(),
              _ActionCell(entry: entry),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.entry});

  final JudgeAssignedIdeaTableEntry entry;

  @override
  Widget build(BuildContext context) {
    return ProblemWorkflowActionPill(
      label: entry.primaryActionLabel,
      contentIcon: AppIcons.scoring,
      semantic: ProblemWorkflowPillSemantic.filledBrand,
      onTap: entry.onPrimaryAction,
      tooltip: entry.primaryActionLabel,
    );
  }
}
