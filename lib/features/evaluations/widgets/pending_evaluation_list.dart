import 'package:flutter/material.dart';

import '../services/judge_evaluation_service.dart';
import 'judge_assigned_idea_table.dart';
import 'judge_event_grouped_pane.dart';
import 'judge_event_grouping.dart';

class PendingEvaluationList extends StatelessWidget {
  const PendingEvaluationList({
    super.key,
    required this.rows,
    required this.onEvaluate,
    required this.onViewDetails,
    required this.onOpenProblem,
    required this.onOpenTeam,
    this.pendingCountByEvent = const <String, int>{},
    this.evaluatedCountByEvent = const <String, int>{},
  });

  final List<JudgeEvaluationPendingRow> rows;
  final void Function(JudgeEvaluationPendingRow row) onEvaluate;
  final void Function(JudgeEvaluationPendingRow row) onViewDetails;
  final void Function(JudgeEvaluationPendingRow row) onOpenProblem;
  final void Function(JudgeEvaluationPendingRow row) onOpenTeam;
  final Map<String, int> pendingCountByEvent;
  final Map<String, int> evaluatedCountByEvent;

  @override
  Widget build(BuildContext context) {
    return JudgeEventGroupedPane<JudgeEvaluationPendingRow>(
      items: rows,
      eventIdOf: (JudgeEvaluationPendingRow row) => row.eventId,
      nameOf: (JudgeEvaluationPendingRow row) => row.eventName,
      scheduleOf: (JudgeEvaluationPendingRow row) => row.eventSchedule,
      statusOf: (JudgeEvaluationPendingRow row) => row.eventStatus,
      startAtOf: (JudgeEvaluationPendingRow row) => row.eventStartAt,
      pendingCountByEvent: pendingCountByEvent,
      evaluatedCountByEvent: evaluatedCountByEvent,
      sort: JudgeEventGroupSort.nearestEvent,
      collapsible: true,
      empty: const JudgeScoringEmptyState(
        title: 'No pending evaluations',
        message: 'Ideas assigned to you for an event will show up here when they are ready to score.',
      ),
      sectionChild: (List<JudgeEvaluationPendingRow> group) {
        return JudgeAssignedIdeaTable(
          shrinkWrap: true,
          emptyMessage: 'No submissions awaiting your evaluation.',
          entries: group
              .map(
                (JudgeEvaluationPendingRow row) => JudgeAssignedIdeaTableEntry.pending(
                  row: row,
                  onEvaluate: () => onEvaluate(row),
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
