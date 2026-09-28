import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';

/// Shared helpers for evaluation template UI (judge dialog + read-only views).
abstract final class EvaluationTemplateHelpers {
  EvaluationTemplateHelpers._();

  static String weightLabel(EvaluationCriterion criterion, EvaluationTemplate template) {
    return percentLabel(criterion.weight, ofTotal: _positiveWeightSum(template.criteria));
  }

  /// Stored weight is a 0–1 fraction; UI always shows percent (e.g. `25%`).
  static String percentLabel(double weight, {double? ofTotal}) {
    final double pct = weight <= 0
        ? 0
        : ofTotal != null && ofTotal > 0
            ? (weight / ofTotal) * 100
            : weight * 100;
    return formatPercent(pct);
  }

  static String formatPercent(double pct) {
    if ((pct - pct.roundToDouble()).abs() < 0.05) return '${pct.round()}%';
    return '${pct.toStringAsFixed(1)}%';
  }

  static double totalWeightPercent(Iterable<EvaluationCriterion> criteria) {
    double sum = 0;
    for (final EvaluationCriterion c in criteria) {
      if (c.weight > 0) sum += c.weight * 100;
    }
    return sum;
  }

  static int totalWeightPercentRounded(Iterable<EvaluationCriterion> criteria) =>
      totalWeightPercent(criteria).round();

  static bool isTotalWeightComplete(Iterable<EvaluationCriterion> criteria) =>
      totalWeightPercentRounded(criteria) == 100;

  static int remainingWeightPercent(Iterable<EvaluationCriterion> criteria) =>
      100 - totalWeightPercentRounded(criteria);

  static int maxAssignablePercent({
    required Iterable<EvaluationCriterion> criteria,
    EvaluationCriterion? editing,
  }) {
    int others = 0;
    for (final EvaluationCriterion c in criteria) {
      if (editing != null && c.criterionId == editing.criterionId) continue;
      if (c.weight > 0) others += (c.weight * 100).round();
    }
    final int max = 100 - others;
    return max < 0 ? 0 : max;
  }

  static String? validateWeights(Iterable<EvaluationCriterion> criteria) {
    if (criteria.isEmpty) return 'At least one criterion is required.';
    for (final EvaluationCriterion c in criteria) {
      if (c.title.trim().isEmpty) return 'Criterion name cannot be empty.';
      if (c.minScore >= c.maxScore) {
        return '${c.title}: minimum score must be less than maximum score.';
      }
    }
    final int total = totalWeightPercentRounded(criteria);
    if (total > 100) return 'Total weightage is $total% and cannot exceed 100%.';
    if (total < 100) return 'Total weightage is $total%. Remaining ${100 - total}% must be allocated.';
    return null;
  }

  static double _positiveWeightSum(Iterable<EvaluationCriterion> criteria) {
    double total = 0;
    for (final EvaluationCriterion c in criteria) {
      if (c.weight > 0) total += c.weight;
    }
    return total;
  }
}
