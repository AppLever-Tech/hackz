import 'package:flutter/material.dart';

import '../services/judge_evaluation_service.dart';
import 'judge_assigned_idea_table.dart';
import 'judge_evaluation_event_header.dart';

class EvaluatedIdeaList extends StatelessWidget {
  const EvaluatedIdeaList({
    super.key,
    required this.rows,
    required this.onViewEvaluation,
    required this.onViewDetails,
    required this.onOpenProblem,
    this.groupByEvent = false,
  });

  final List<JudgeEvaluationEvaluatedRow> rows;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewEvaluation;
  final void Function(JudgeEvaluationEvaluatedRow row) onViewDetails;
  final void Function(JudgeEvaluationEvaluatedRow row) onOpenProblem;
  final bool groupByEvent;

  @override
  Widget build(BuildContext context) {
    JudgeAssignedIdeaTable tableFor(List<JudgeEvaluationEvaluatedRow> group, {required bool shrinkWrap}) {
      return JudgeAssignedIdeaTable(
        shrinkWrap: shrinkWrap,
        entries: group
            .map(
              (JudgeEvaluationEvaluatedRow row) => JudgeAssignedIdeaTableEntry.evaluated(
                row: row,
                onReview: () => onViewEvaluation(row),
                onViewDetails: () => onViewDetails(row),
                onOpenProblem: () => onOpenProblem(row),
              ),
            )
            .toList(growable: false),
        emptyMessage: 'You have not submitted evaluations yet.',
      );
    }

    if (!groupByEvent || rows.isEmpty) return tableFor(rows, shrinkWrap: false);

    final Map<String, List<JudgeEvaluationEvaluatedRow>> grouped = <String, List<JudgeEvaluationEvaluatedRow>>{};
    for (final JudgeEvaluationEvaluatedRow row in rows) {
      grouped.putIfAbsent(row.ideathonId.trim(), () => <JudgeEvaluationEvaluatedRow>[]).add(row);
    }
    final List<String> keys = grouped.keys.toList(growable: false)
      ..sort((String a, String b) {
        final String na = grouped[a]!.first.ideathonName;
        final String nb = grouped[b]!.first.ideathonName;
        return na.toLowerCase().compareTo(nb.toLowerCase());
      });

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: <Widget>[
        for (final String key in keys) ...<Widget>[
          JudgeEvaluationEventHeader(
            name: grouped[key]!.first.ideathonName.trim().isEmpty
                ? 'Assigned ideas'
                : grouped[key]!.first.ideathonName.trim(),
            schedule: grouped[key]!.first.ideathonSchedule,
          ),
          tableFor(grouped[key]!, shrinkWrap: true),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
