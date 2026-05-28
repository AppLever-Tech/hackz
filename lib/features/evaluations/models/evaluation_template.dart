import 'evaluation_criterion.dart';

/// A reusable judging rubric persisted under
/// `hkzOrganizations/{orgId}/settings/org_settings.evaluationTemplates[]`.
///
/// Judges score against the [criteria]; the overall score is the
/// weight-normalized average via [computeOverall].
class EvaluationTemplate {
  const EvaluationTemplate({
    required this.templateId,
    required this.templateName,
    this.description,
    required this.scoringScale,
    required this.criteria,
    this.isDefault = false,
    this.active = true,
  });

  /// Stable id within the org (e.g. `ideathon`, `research`).
  final String templateId;

  final String templateName;
  final String? description;

  /// Default upper bound for criteria scores (criteria can override via
  /// [EvaluationCriterion.maxScore]).
  final int scoringScale;

  final List<EvaluationCriterion> criteria;

  /// When true, this template is the org default. Exactly one template per
  /// org is expected to carry this flag.
  final bool isDefault;

  /// When false, the template is hidden from new evaluations but kept for
  /// historical scores that referenced it.
  final bool active;

  /// Sorted view of [criteria] by [EvaluationCriterion.displayOrder] then
  /// title. Cheap; build once per render.
  List<EvaluationCriterion> get orderedCriteria {
    final List<EvaluationCriterion> list = List<EvaluationCriterion>.from(criteria);
    list.sort((EvaluationCriterion a, EvaluationCriterion b) {
      final int o = a.displayOrder.compareTo(b.displayOrder);
      if (o != 0) return o;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return list;
  }

  List<EvaluationCriterion> get orgCriteria => orderedCriteria
      .where((EvaluationCriterion c) =>
          c.sourceType == EvaluationCriterionSourceType.org)
      .toList(growable: false);

  List<EvaluationCriterion> get departmentExtensionCriteria => orderedCriteria
      .where((EvaluationCriterion c) =>
          c.sourceType == EvaluationCriterionSourceType.department)
      .toList(growable: false);

  EvaluationTemplate withDepartmentExtensions({
    required String departmentCode,
    required List<EvaluationCriterion> extensions,
  }) {
    final String dept = departmentCode.trim().toUpperCase();
    if (dept.isEmpty || extensions.isEmpty) return this;
    final Set<String> existing = <String>{
      for (final EvaluationCriterion c in criteria) c.criterionId,
    };
    final List<EvaluationCriterion> additions = <EvaluationCriterion>[];
    int nextOrder = criteria.isEmpty
        ? 1
        : criteria
                .map((EvaluationCriterion c) => c.displayOrder)
                .reduce((int a, int b) => a > b ? a : b) +
            1;
    for (final EvaluationCriterion c in extensions) {
      if (existing.contains(c.criterionId)) continue;
      additions.add(c.copyWith(
        sourceType: EvaluationCriterionSourceType.department,
        ownerDepartmentCode:
            c.ownerDepartmentCode.trim().isEmpty ? dept : c.ownerDepartmentCode,
        displayOrder: c.displayOrder <= 0 ? nextOrder : c.displayOrder,
      ));
      nextOrder++;
    }
    if (additions.isEmpty) return this;
    return copyWith(criteria: <EvaluationCriterion>[...criteria, ...additions]);
  }

  /// Weight-normalized score in `[0, scoringScale]`. Returns `0` when no
  /// criterion is scored. Unknown criterion ids in [criteriaScores] are
  /// ignored.
  double computeOverall(Map<String, double> criteriaScores) {
    if (criteria.isEmpty) return 0;
    double weightedSum = 0;
    double weightTotal = 0;
    for (final EvaluationCriterion c in criteria) {
      final double? raw = criteriaScores[c.criterionId];
      if (raw == null) continue;
      final double clamped = raw.clamp(c.minScore.toDouble(), c.maxScore.toDouble());
      // Normalize each criterion to a [0, scoringScale] range so criteria
      // with different min/max contribute on the same scale.
      final double range = (c.maxScore - c.minScore).toDouble();
      final double unit = range <= 0 ? 0 : (clamped - c.minScore) / range;
      final double normalized = unit * scoringScale;
      final double w = c.weight <= 0 ? 0 : c.weight;
      weightedSum += normalized * w;
      weightTotal += w;
    }
    if (weightTotal <= 0) return 0;
    return (weightedSum / weightTotal).clamp(0.0, scoringScale.toDouble());
  }

  EvaluationTemplate copyWith({
    String? templateId,
    String? templateName,
    String? description,
    int? scoringScale,
    List<EvaluationCriterion>? criteria,
    bool? isDefault,
    bool? active,
  }) {
    return EvaluationTemplate(
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      description: description ?? this.description,
      scoringScale: scoringScale ?? this.scoringScale,
      criteria: criteria ?? this.criteria,
      isDefault: isDefault ?? this.isDefault,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'templateId': templateId,
      'templateName': templateName,
      'description': description,
      'scoringScale': scoringScale,
      'criteria': criteria.map((EvaluationCriterion c) => c.toMap()).toList(growable: false),
      'isDefault': isDefault,
      'active': active,
    };
  }

  factory EvaluationTemplate.fromMap(Map<String, dynamic> map) {
    final Object? rawCriteria = map['criteria'];
    final List<EvaluationCriterion> parsed = <EvaluationCriterion>[];
    if (rawCriteria is List) {
      for (final Object? item in rawCriteria) {
        if (item is Map) {
          parsed.add(EvaluationCriterion.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return EvaluationTemplate(
      templateId: ((map['templateId'] as String?) ?? '').trim(),
      templateName: ((map['templateName'] as String?) ?? '').trim(),
      description: (map['description'] as String?)?.trim(),
      scoringScale: (map['scoringScale'] as num?)?.toInt() ?? 10,
      criteria: parsed,
      isDefault: (map['isDefault'] as bool?) ?? false,
      active: (map['active'] as bool?) ?? true,
    );
  }
}
