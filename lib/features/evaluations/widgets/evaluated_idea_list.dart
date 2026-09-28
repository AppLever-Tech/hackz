import 'package:flutter/material.dart';

import '../services/judge_evaluation_service.dart';
import 'judge_assigned_idea_table.dart';
import 'judge_event_grouped_pane.dart';
import 'judge_event_grouping.dart';

class EvaluatedIdeaList extends StatelessWidget {
  const EvaluatedIdeaList({
    super.key,
    required this.rows,
    required this.onViewEvaluation,
    required this.onViewDetails,
    required this.onOpenProblem,
    required this.onOpenTeam,
    this.pendingCountByEvent = const <String, int>{},
    this.evaluatedCountByEvent = const <String, int>{},
  });

  final List<JudgeEvaluationEvaluatedRow> rows;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewEvaluation;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewDetails;
  final void Function(JudgeEvaluationEvaluatedRow row) onOpenProblem;
  final void Function(JudgeEvaluationEvaluatedRow row) onOpenTeam;
  final Map<String, int> pendingCountByEvent;
  final Map<String, int> evaluatedCountByEvent;

  @override
  Widget build(BuildContext context) {
    return JudgeEventGroupedPane<JudgeEvaluationEvaluatedRow>(
      items: rows,
      eventIdOf: (JudgeEvaluationEvaluatedRow row) => row.eventId,
      nameOf: (JudgeEvaluationEvaluatedRow row) => row.eventName,
      scheduleOf: (JudgeEvaluationEvaluatedRow row) => row.eventSchedule,
      statusOf: (JudgeEvaluationEvaluatedRow row) => row.eventStatus,
      startAtOf: (JudgeEvaluationEvaluatedRow row) => row.eventStartAt,
      activityAtOf: (JudgeEvaluationEvaluatedRow row) => row.evaluatedAt,
      pendingCountByEvent: pendingCountByEvent,
      evaluatedCountByEvent: evaluatedCountByEvent,
      sort: JudgeEventGroupSort.mostRecentActivity,
      collapsible: true,
      empty: const JudgeScoringEmptyState(
        title: 'No evaluated ideas',
        message: 'Submitted event evaluations will appear here.',
      ),
      sectionChild: (List<JudgeEvaluationEvaluatedRow> group) {
        return JudgeAssignedIdeaTable(
          shrinkWrap: true,
          emptyMessage: 'You have not submitted evaluations yet.',
          entries: group
              .map(
                (JudgeEvaluationEvaluatedRow row) => JudgeAssignedIdeaTableEntry.evaluated(
                  row: row,
                  onReview: () => onViewEvaluation(row),
                  onViewDetails: () => onViewDetails(row),
                  onOpenProblem: () => onOpenProblem(row),
                  onOpenTeam: () => onOpenTeam(row),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
