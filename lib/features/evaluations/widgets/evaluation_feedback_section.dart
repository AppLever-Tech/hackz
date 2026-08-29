import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../services/judge_evaluation_service.dart';
import 'judge_event_grouped_pane.dart';

class EvaluationFeedbackSection extends StatelessWidget {
  const EvaluationFeedbackSection({
    super.key,
    required this.rows,
    this.pendingCountByEvent = const <String, int>{},
    this.evaluatedCountByEvent = const <String, int>{},
    this.onViewEvaluation,
  });

  final List<JudgeEvaluationFeedbackRow> rows;
  final Map<String, int> pendingCountByEvent;
  final Map<String, int> evaluatedCountByEvent;
  final void Function(JudgeEvaluationFeedbackRow row)? onViewEvaluation;

  @override
  Widget build(BuildContext context) {
    return JudgeEventGroupedPane<JudgeEvaluationFeedbackRow>(
      items: rows,
      eventIdOf: (JudgeEvaluationFeedbackRow row) => row.eventId,
      nameOf: (JudgeEvaluationFeedbackRow row) => row.eventName,
      scheduleOf: (JudgeEvaluationFeedbackRow row) => row.eventSchedule,
      statusOf: (JudgeEvaluationFeedbackRow row) => row.eventStatus,
      pendingCountByEvent: pendingCountByEvent,
      evaluatedCountByEvent: evaluatedCountByEvent,
      empty: const JudgeScoringEmptyState(
        title: 'No event feedback yet',
        message: 'Remarks from your event evaluations will appear here.',
      ),
      sectionChild: (List<JudgeEvaluationFeedbackRow> group) {
        if (ResponsiveHelper.isMobile(context)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < group.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 8),
                _FeedbackCard(row: group[i], onViewEvaluation: onViewEvaluation),
              ],
            ],
          );
        }
        return _FeedbackTable(rows: group, onViewEvaluation: onViewEvaluation);
      },
    );
  }
}

class _FeedbackTable extends StatelessWidget {
  const _FeedbackTable({required this.rows, this.onViewEvaluation});

  final List<JudgeEvaluationFeedbackRow> rows;
  final void Function(JudgeEvaluationFeedbackRow row)? onViewEvaluation;

  static const Color _headerBg = Color(0xFFF1F4FB);
  static const Color _border = Color(0xFFE3E8F4);
  static const Color _altRowBg = Color(0xFFFAFBFE);

  @override
  Widget build(BuildContext context) {
    const TextStyle headerStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155));
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: const BoxDecoration(
              color: _headerBg,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Row(
              children: <Widget>[
                Expanded(flex: 3, child: Text('Idea', style: headerStyle)),
                SizedBox(width: 8),
                Expanded(flex: 3, child: Text('Problem / Team', style: headerStyle)),
                SizedBox(width: 8),
                SizedBox(width: 64, child: Text('Score', style: headerStyle)),
                SizedBox(width: 8),
                Expanded(flex: 4, child: Text('Feedback', style: headerStyle)),
                SizedBox(width: 8),
                SizedBox(width: 148, child: Text('Action', textAlign: TextAlign.end, style: headerStyle)),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1, color: _border),
            itemBuilder: (BuildContext context, int index) {
              return ColoredBox(
                color: index.isEven ? Colors.white : _altRowBg,
                child: _FeedbackWideRow(row: rows[index], onViewEvaluation: onViewEvaluation),
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _pill(Widget child) {
  return Align(
    alignment: Alignment.centerLeft,
    child: child,
  );
}

class _FeedbackWideRow extends StatelessWidget {
  const _FeedbackWideRow({required this.row, this.onViewEvaluation});

  final JudgeEvaluationFeedbackRow row;
  final void Function(JudgeEvaluationFeedbackRow row)? onViewEvaluation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: _pill(_ideaPill(context, row))),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _pill(_problemPill(context, row)),
                const SizedBox(height: 6),
                _pill(_teamPill(context, row)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              row.overallScore.toStringAsFixed(1),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              row.remarksExcerpt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 148,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ViewAction(row: row, onViewEvaluation: onViewEvaluation),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.row, this.onViewEvaluation});

  final JudgeEvaluationFeedbackRow row;
  final void Function(JudgeEvaluationFeedbackRow row)? onViewEvaluation;

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
            children: <Widget>[
              _ideaPill(context, row),
              _problemPill(context, row),
              _teamPill(context, row),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(AppIcons.scoring, size: 14, color: Color(0xFF059669)),
              const SizedBox(width: 4),
              Text(
                row.overallScore.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            row.remarksExcerpt,
            style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF334155), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _ViewAction(row: row, onViewEvaluation: onViewEvaluation),
          ),
        ],
      ),
    );
  }
}

class _ViewAction extends StatelessWidget {
  const _ViewAction({required this.row, this.onViewEvaluation});

  final JudgeEvaluationFeedbackRow row;
  final void Function(JudgeEvaluationFeedbackRow row)? onViewEvaluation;

  @override
  Widget build(BuildContext context) {
    final bool canOpen = row.scoreId.trim().isNotEmpty;
    return ProblemWorkflowActionPill(
      label: 'View Evaluation',
      contentIcon: AppIcons.scoring,
      semantic: ProblemWorkflowPillSemantic.filledBrand,
      enabled: canOpen,
      onTap: !canOpen
          ? null
          : () {
              if (onViewEvaluation != null) {
                onViewEvaluation!(row);
                return;
              }
              WorkspaceNavigator.openEvaluation(
                context,
                row.ideaId,
                ideathonId: row.ideathonId,
              );
            },
    );
  }
}

Widget _ideaPill(BuildContext context, JudgeEvaluationFeedbackRow row) {
  return EntityCardPills.workspace(
    row.ideaTitle,
    ContextPillSemantic.idea,
    () => WorkspaceNavigator.openIdea(context, row.ideaId),
    icon: AppIcons.ideas,
  );
}

Widget _problemPill(BuildContext context, JudgeEvaluationFeedbackRow row) {
  final String label = row.problemTitle.trim().isEmpty ? 'Problem' : row.problemTitle.trim();
  if (row.problemId.trim().isEmpty) {
    return EntityCardPills.meta(label, icon: AppIcons.problems);
  }
  return EntityCardPills.workspace(
    label,
    ContextPillSemantic.problem,
    () => WorkspaceNavigator.openProblem(context, row.problemId),
    icon: AppIcons.problems,
  );
}

Widget _teamPill(BuildContext context, JudgeEvaluationFeedbackRow row) {
  final String label = row.teamName.trim().isEmpty ? 'Team' : row.teamName.trim();
  if (row.teamId.trim().isEmpty) {
    return EntityCardPills.meta(label, icon: AppIcons.teams);
  }
  return EntityCardPills.workspace(
    label,
    ContextPillSemantic.team,
    () => WorkspaceNavigator.openTeam(context, row.teamId),
    icon: AppIcons.teams,
  );
}
