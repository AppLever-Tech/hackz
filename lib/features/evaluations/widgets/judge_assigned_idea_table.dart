import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../services/judge_evaluation_service.dart';
import 'judge_assignment_row_status.dart';

/// Normalized row for the judge assigned-ideas table / mobile cards.
class JudgeAssignedIdeaTableEntry {
  const JudgeAssignedIdeaTableEntry({
    required this.ideaId,
    required this.ideaTitle,
    required this.problemId,
    required this.problemLabel,
    required this.teamId,
    required this.teamName,
    required this.workflowStatus,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.onOpenIdea,
    required this.onOpenProblem,
    required this.onOpenTeam,
    this.score,
  });

  factory JudgeAssignedIdeaTableEntry.pending({
    required JudgeEvaluationPendingRow row,
    required VoidCallback onEvaluate,
    required VoidCallback onViewDetails,
    required VoidCallback onOpenProblem,
    required VoidCallback onOpenTeam,
  }) {
    return JudgeAssignedIdeaTableEntry(
      ideaId: row.ideaId,
      ideaTitle: _ideaTitle(row.idea),
      problemId: row.idea.problemId,
      problemLabel: row.problemTitle.trim().isEmpty ? 'Problem' : row.problemTitle.trim(),
      teamId: row.idea.teamId,
      teamName: row.teamName,
      workflowStatus: row.workflowStatus,
      primaryActionLabel: 'Evaluate',
      onPrimaryAction: onEvaluate,
      onOpenIdea: onViewDetails,
      onOpenProblem: onOpenProblem,
      onOpenTeam: onOpenTeam,
    );
  }

  factory JudgeAssignedIdeaTableEntry.evaluated({
    required JudgeEvaluationEvaluatedRow row,
    required VoidCallback onReview,
    required VoidCallback onViewDetails,
    required VoidCallback onOpenProblem,
    required VoidCallback onOpenTeam,
  }) {
    return JudgeAssignedIdeaTableEntry(
      ideaId: row.ideaId,
      ideaTitle: _ideaTitle(row.idea),
      problemId: row.idea.problemId,
      problemLabel: row.problemTitle.trim().isEmpty ? 'Problem' : row.problemTitle.trim(),
      teamId: row.idea.teamId,
      teamName: row.teamName,
      workflowStatus: row.workflowStatus,
      score: row.score,
      primaryActionLabel: 'Review',
      onPrimaryAction: onReview,
      onOpenIdea: onViewDetails,
      onOpenProblem: onOpenProblem,
      onOpenTeam: onOpenTeam,
    );
  }

  final String ideaId;
  final String ideaTitle;
  final String problemId;
  final String problemLabel;
  final String teamId;
  final String teamName;
  final JudgeAssignmentRowStatus workflowStatus;
  final double? score;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onOpenIdea;
  final VoidCallback onOpenProblem;
  final VoidCallback onOpenTeam;

  static String _ideaTitle(IdeaModel idea) {
    final String title = idea.ideaTitle.trim();
    if (title.isNotEmpty) return title;
    if (idea.problemNumber.trim().isNotEmpty) return idea.problemNumber.trim();
    return 'Untitled idea';
  }
}

/// Desktop table / mobile cards for ideas assigned to a judge within one event.
class JudgeAssignedIdeaTable extends StatelessWidget {
  const JudgeAssignedIdeaTable({
    super.key,
    required this.entries,
    this.emptyMessage = 'No assigned ideas found.',
    this.shrinkWrap = false,
  });

  final List<JudgeAssignedIdeaTableEntry> entries;
  final String emptyMessage;
  final bool shrinkWrap;

  static const Color _headerBg = Color(0xFFF1F4FB);
  static const Color _border = Color(0xFFE3E8F4);
  static const Color _altRowBg = Color(0xFFFAFBFE);
  static const Color _headerText = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = ResponsiveHelper.isMobile(context) ||
            WorkspaceTheme.isCompactWidth(constraints.maxWidth);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < entries.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 8),
                _IdeaCard(entry: entries[i]),
              ],
            ],
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _TableHeader(),
              if (shrinkWrap)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _border),
                  itemBuilder: (BuildContext context, int index) {
                    return ColoredBox(
                      color: index.isEven ? Colors.white : _altRowBg,
                      child: _WideRow(entry: entries[index]),
                    );
                  },
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _border),
                    itemBuilder: (BuildContext context, int index) {
                      return ColoredBox(
                        color: index.isEven ? Colors.white : _altRowBg,
                        child: _WideRow(entry: entries[index]),
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
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: JudgeAssignedIdeaTable._headerText);
    return Container(
      decoration: const BoxDecoration(
        color: JudgeAssignedIdeaTable._headerBg,
        border: Border(bottom: BorderSide(color: JudgeAssignedIdeaTable._border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 4, child: Text('Idea', style: style)),
          SizedBox(width: 10),
          Expanded(flex: 3, child: Text('Problem', style: style)),
          SizedBox(width: 10),
          Expanded(flex: 3, child: Text('Team', style: style)),
          SizedBox(width: 10),
          SizedBox(width: 108, child: Text('Status / Score', style: style)),
          SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: Text('Action', textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}

Widget _pillCell(Widget child) {
  return Align(
    alignment: Alignment.centerLeft,
    child: child,
  );
}

Widget _ideaPill(JudgeAssignedIdeaTableEntry entry) {
  return EntityCardPills.workspace(
    entry.ideaTitle,
    ContextPillSemantic.idea,
    entry.onOpenIdea,
    icon: AppIcons.ideas,
  );
}

Widget _problemPill(JudgeAssignedIdeaTableEntry entry) {
  return EntityCardPills.workspace(
    entry.problemLabel,
    ContextPillSemantic.problem,
    entry.onOpenProblem,
    icon: AppIcons.problems,
  );
}

Widget _teamPill(JudgeAssignedIdeaTableEntry entry) {
  final String label = entry.teamName.trim().isEmpty ? 'Team' : entry.teamName.trim();
  if (entry.teamId.trim().isEmpty) {
    return EntityCardPills.meta(label, icon: AppIcons.teams);
  }
  return EntityCardPills.workspace(
    label,
    ContextPillSemantic.team,
    entry.onOpenTeam,
    icon: AppIcons.teams,
  );
}

class _StatusOrScore extends StatelessWidget {
  const _StatusOrScore({required this.entry});

  final JudgeAssignedIdeaTableEntry entry;

  @override
  Widget build(BuildContext context) {
    final double? score = entry.score;
    if (score == null) {
      return JudgeAssignmentRowStatusPill(status: entry.workflowStatus);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(AppIcons.scoring, size: 14, color: Color(0xFF059669)),
        const SizedBox(width: 4),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
        ),
      ],
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

class _WideRow extends StatelessWidget {
  const _WideRow({required this.entry});

  final JudgeAssignedIdeaTableEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(flex: 4, child: _pillCell(_ideaPill(entry))),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: _pillCell(_problemPill(entry))),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: _pillCell(_teamPill(entry))),
          const SizedBox(width: 10),
          SizedBox(width: 108, child: Align(alignment: Alignment.centerLeft, child: _StatusOrScore(entry: entry))),
          const SizedBox(width: 10),
          SizedBox(width: 104, child: Align(alignment: Alignment.centerRight, child: _ActionCell(entry: entry))),
        ],
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({required this.entry});

  final JudgeAssignedIdeaTableEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _ideaPill(entry),
              _problemPill(entry),
              _teamPill(entry),
              _StatusOrScore(entry: entry),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _ActionCell(entry: entry),
          ),
        ],
      ),
    );
  }
}
