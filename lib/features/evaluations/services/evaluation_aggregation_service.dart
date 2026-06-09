import '../models/score_model.dart';

/// Aggregated evaluation metrics for an idea (single source of truth).
class IdeaEvaluationAggregate {
  const IdeaEvaluationAggregate({
    required this.averageScore,
    required this.highestScore,
    required this.lowestScore,
    required this.totalEvaluators,
  });

  const IdeaEvaluationAggregate.empty()
      : averageScore = null,
        highestScore = null,
        lowestScore = null,
        totalEvaluators = 0;

  final double? averageScore;
  final double? highestScore;
  final double? lowestScore;
  final int totalEvaluators;

  bool get hasScores => totalEvaluators > 0 && averageScore != null;

  Map<String, dynamic> toFirestoreFields() {
    return <String, dynamic>{
      if (averageScore != null) 'averageScore': averageScore,
      if (highestScore != null) 'highestScore': highestScore,
      if (lowestScore != null) 'lowestScore': lowestScore,
      'totalEvaluators': totalEvaluators,
    };
  }
}

/// Centralized evaluation score aggregation and idea persistence.
abstract final class EvaluationAggregationService {
  EvaluationAggregationService._();

  static IdeaEvaluationAggregate computeFromScores(List<ScoreModel> scores) {
    if (scores.isEmpty) return const IdeaEvaluationAggregate.empty();
    final List<double> values = scores.map((ScoreModel s) => s.score).toList(growable: false);
    final double sum = values.fold<double>(0, (double a, double b) => a + b);
    final double average = sum / values.length;
    values.sort();
    return IdeaEvaluationAggregate(
      averageScore: double.parse(average.toStringAsFixed(2)),
      highestScore: values.last,
      lowestScore: values.first,
      totalEvaluators: values.length,
    );
  }

  static IdeaEvaluationAggregate fromIdeaFields({
    double? averageScore,
    double? highestScore,
    double? lowestScore,
    int totalEvaluators = 0,
  }) {
    if (totalEvaluators <= 0 || averageScore == null) {
      return const IdeaEvaluationAggregate.empty();
    }
    return IdeaEvaluationAggregate(
      averageScore: averageScore,
      highestScore: highestScore,
      lowestScore: lowestScore,
      totalEvaluators: totalEvaluators,
    );
  }
}
