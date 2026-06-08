import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';

/// Shared helpers for evaluation template UI (judge dialog + read-only views).
abstract final class EvaluationTemplateHelpers {
  EvaluationTemplateHelpers._();

  static String weightLabel(EvaluationCriterion criterion, EvaluationTemplate template) {
    double total = 0;
    for (final EvaluationCriterion c in template.criteria) {
      if (c.weight > 0) total += c.weight;
    }
    if (total <= 0) return '—';
    final double pct = (criterion.weight / total) * 100;
    if (pct >= 10) return '${pct.toStringAsFixed(0)}%';
    return '${pct.toStringAsFixed(1)}%';
  }
}
