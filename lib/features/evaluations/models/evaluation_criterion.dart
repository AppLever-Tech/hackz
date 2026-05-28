enum EvaluationCriterionSourceType {
  org('org'),
  department('department');

  const EvaluationCriterionSourceType(this.value);
  final String value;

  static EvaluationCriterionSourceType fromRaw(String raw) {
    return raw.trim().toLowerCase() == 'department'
        ? EvaluationCriterionSourceType.department
        : EvaluationCriterionSourceType.org;
  }
}

/// One scoring dimension inside an [EvaluationTemplate].
///
/// Persisted as a map inside `org_settings.evaluationTemplates[].criteria[]`.
class EvaluationCriterion {
  const EvaluationCriterion({
    required this.criterionId,
    required this.title,
    this.description,
    required this.weight,
    required this.minScore,
    required this.maxScore,
    this.commentsEnabled = false,
    required this.displayOrder,
    this.sourceType = EvaluationCriterionSourceType.org,
    this.ownerDepartmentCode = '',
  });

  /// Stable id within the template (e.g. `innovation`, `impact`). Used as the
  /// key inside `ScoreModel.criteriaScores` / `criteriaComments` so judges'
  /// answers survive template edits as long as the id is preserved.
  final String criterionId;

  /// Human-readable label shown to the judge (e.g. `Innovation`).
  final String title;

  /// Optional helper text shown beneath the title.
  final String? description;

  /// Relative weight when computing the overall score. Weights need not sum
  /// to 1.0 — [EvaluationTemplate.computeOverall] normalizes them.
  final double weight;

  final int minScore;
  final int maxScore;

  /// When true, the judge can leave a short note specific to this criterion.
  final bool commentsEnabled;

  /// Render order within the template (ascending).
  final int displayOrder;
  final EvaluationCriterionSourceType sourceType;
  final String ownerDepartmentCode;

  EvaluationCriterion copyWith({
    String? criterionId,
    String? title,
    String? description,
    double? weight,
    int? minScore,
    int? maxScore,
    bool? commentsEnabled,
    int? displayOrder,
    EvaluationCriterionSourceType? sourceType,
    String? ownerDepartmentCode,
  }) {
    return EvaluationCriterion(
      criterionId: criterionId ?? this.criterionId,
      title: title ?? this.title,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      displayOrder: displayOrder ?? this.displayOrder,
      sourceType: sourceType ?? this.sourceType,
      ownerDepartmentCode: ownerDepartmentCode ?? this.ownerDepartmentCode,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'criterionId': criterionId,
      'title': title,
      'description': description,
      'weight': weight,
      'minScore': minScore,
      'maxScore': maxScore,
      'commentsEnabled': commentsEnabled,
      'displayOrder': displayOrder,
      'sourceType': sourceType.value,
      'ownerDepartmentCode': ownerDepartmentCode,
    };
  }

  factory EvaluationCriterion.fromMap(Map<String, dynamic> map) {
    final num? rawWeight = map['weight'] as num?;
    final num? rawMin = map['minScore'] as num?;
    final num? rawMax = map['maxScore'] as num?;
    return EvaluationCriterion(
      criterionId: ((map['criterionId'] as String?) ?? '').trim(),
      title: ((map['title'] as String?) ?? '').trim(),
      description: (map['description'] as String?)?.trim(),
      weight: rawWeight?.toDouble() ?? 1.0,
      minScore: rawMin?.toInt() ?? 1,
      maxScore: rawMax?.toInt() ?? 10,
      commentsEnabled: (map['commentsEnabled'] as bool?) ?? false,
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      sourceType: EvaluationCriterionSourceType.fromRaw(
        (map['sourceType'] as String?) ?? '',
      ),
      ownerDepartmentCode:
          ((map['ownerDepartmentCode'] as String?) ?? '').trim().toUpperCase(),
    );
  }
}
