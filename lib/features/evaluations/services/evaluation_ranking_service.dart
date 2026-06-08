import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import '../../problems/models/problem_model.dart';
import 'evaluation_aggregation_service.dart';

/// Rank calculation for evaluated ideas (average score DESC).
abstract final class EvaluationRankingService {
  EvaluationRankingService._();

  static Future<void> persistRanks(List<EvaluationResultsRow> rows) async {
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    var count = 0;
    for (final EvaluationResultsRow row in rows) {
      if (row.rank <= 0) continue;
      if (row.idea.evaluationRank == row.rank) continue;
      batch.update(
        FirebaseFirestore.instance.collection(FirestoreUtils.hkzIdeas).doc(row.idea.ideaId),
        <String, dynamic>{IdeaModel.fieldEvaluationRank: row.rank},
      );
      count++;
      if (count >= 400) break;
    }
    if (count == 0) return;
    await batch.commit();
  }

  static List<EvaluationResultsRow> buildRankedRows({
    required List<IdeaModel> ideas,
    required Map<String, ProblemModel> problems,
  }) {
    final List<IdeaModel> sortable = ideas
        .where((IdeaModel i) => i.hasEvaluationAggregate && i.averageScore != null)
        .toList(growable: true)
      ..sort((IdeaModel a, IdeaModel b) {
        final double av = a.averageScore ?? 0;
        final double bv = b.averageScore ?? 0;
        final int byScore = bv.compareTo(av);
        if (byScore != 0) return byScore;
        return a.ideaId.compareTo(b.ideaId);
      });

    final List<EvaluationResultsRow> rows = <EvaluationResultsRow>[];
    for (int i = 0; i < sortable.length; i++) {
      final IdeaModel idea = sortable[i];
      final ProblemModel? problem = problems[idea.problemId];
      rows.add(
        EvaluationResultsRow(
          rank: i + 1,
          idea: idea,
          problemTitle: (problem?.title ?? idea.problemTitle).trim().isEmpty
              ? idea.problemId
              : (problem?.title ?? idea.problemTitle).trim(),
          category: (problem?.category ?? '').trim(),
          aggregate: EvaluationAggregationService.fromIdeaFields(
            averageScore: idea.averageScore,
            highestScore: idea.highestScore,
            lowestScore: idea.lowestScore,
            totalEvaluators: idea.totalEvaluators,
          ),
        ),
      );
    }

    final Set<String> rankedIds = sortable.map((IdeaModel i) => i.ideaId).toSet();
    for (final IdeaModel idea in ideas) {
      if (rankedIds.contains(idea.ideaId)) continue;
      final ProblemModel? problem = problems[idea.problemId];
      rows.add(
        EvaluationResultsRow(
          rank: 0,
          idea: idea,
          problemTitle: (problem?.title ?? idea.problemTitle).trim().isEmpty
              ? idea.problemId
              : (problem?.title ?? idea.problemTitle).trim(),
          category: (problem?.category ?? '').trim(),
          aggregate: EvaluationAggregationService.fromIdeaFields(
            averageScore: idea.averageScore,
            highestScore: idea.highestScore,
            lowestScore: idea.lowestScore,
            totalEvaluators: idea.totalEvaluators,
          ),
        ),
      );
    }

    return rows;
  }
}

/// One ranked row in the Evaluation Results workspace table.
class EvaluationResultsRow {
  const EvaluationResultsRow({
    required this.rank,
    required this.idea,
    required this.problemTitle,
    required this.category,
    required this.aggregate,
  });

  final int rank;
  final IdeaModel idea;
  final String problemTitle;
  final String category;
  final IdeaEvaluationAggregate aggregate;
}
