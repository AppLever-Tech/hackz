import 'package:cloud_firestore/cloud_firestore.dart';

/// One judge's evaluation of one idea.
///
/// `score` is now the **auto-computed weighted overall** derived from the
/// criteria scores against the [templateId] template. Per-criterion data
/// lives on [criteriaScores] / [criteriaComments] keyed by criterion id.
///
/// `feedback` is now the optional **overall** remarks. Legacy v1 records may
/// store a `[[hackz_eval_v1]]…` codec prefix in this field; the evaluation
/// workspace loader decodes that for backward-compatible display only.
class ScoreModel {
  const ScoreModel({
    required this.scoreId,
    required this.ideaId,
    required this.judgeId,
    required this.score,
    required this.feedback,
    required this.createdAt,
    required this.orgId,
    required this.departmentCode,
    this.templateId = '',
    this.criteriaScores = const <String, double>{},
    this.criteriaComments = const <String, String>{},
  });

  final String scoreId;
  final String ideaId;
  final String judgeId;
  final double score;
  final String feedback;
  final DateTime createdAt;
  final String orgId;
  final String departmentCode;

  /// Stable id of the [EvaluationTemplate] this score was authored against.
  /// Empty for legacy v1 records.
  final String templateId;

  /// Map of `criterionId → raw score` for the template's criteria.
  final Map<String, double> criteriaScores;

  /// Map of `criterionId → optional comment`. Only criterions whose template
  /// has `commentsEnabled: true` are expected to populate this map; other
  /// keys are dropped on the read side.
  final Map<String, String> criteriaComments;

  bool get hasStructuredCriteria => criteriaScores.isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'scoreId': scoreId,
      'ideaId': ideaId,
      'judgeId': judgeId,
      'score': score,
      'feedback': feedback,
      'createdAt': Timestamp.fromDate(createdAt),
      'orgId': orgId,
      'departmentCode': departmentCode,
      'templateId': templateId,
      'criteriaScores': criteriaScores,
      'criteriaComments': criteriaComments,
    };
  }

  factory ScoreModel.fromMap(String scoreId, Map<String, dynamic> map) {
    return ScoreModel(
      scoreId: ((map['scoreId'] as String?) ?? '').trim().isNotEmpty
          ? (map['scoreId'] as String).trim()
          : scoreId,
      ideaId: ((map['ideaId'] as String?) ?? '').trim(),
      judgeId: ((map['judgeId'] as String?) ?? '').trim(),
      score: ((map['score'] as num?) ?? 0).toDouble(),
      feedback: ((map['feedback'] as String?) ?? '').trim(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      templateId: ((map['templateId'] as String?) ?? '').trim(),
      criteriaScores: _decodeNumMap(map['criteriaScores']),
      criteriaComments: _decodeStringMap(map['criteriaComments']),
    );
  }

  ScoreModel copyWith({
    String? scoreId,
    String? ideaId,
    String? judgeId,
    double? score,
    String? feedback,
    DateTime? createdAt,
    String? orgId,
    String? departmentCode,
    String? templateId,
    Map<String, double>? criteriaScores,
    Map<String, String>? criteriaComments,
  }) {
    return ScoreModel(
      scoreId: scoreId ?? this.scoreId,
      ideaId: ideaId ?? this.ideaId,
      judgeId: judgeId ?? this.judgeId,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      orgId: orgId ?? this.orgId,
      departmentCode: departmentCode ?? this.departmentCode,
      templateId: templateId ?? this.templateId,
      criteriaScores: criteriaScores ?? this.criteriaScores,
      criteriaComments: criteriaComments ?? this.criteriaComments,
    );
  }
}

Map<String, double> _decodeNumMap(Object? raw) {
  if (raw is! Map) return const <String, double>{};
  final Map<String, double> out = <String, double>{};
  raw.forEach((Object? k, Object? v) {
    if (k is String && v is num) out[k] = v.toDouble();
  });
  return out;
}

Map<String, String> _decodeStringMap(Object? raw) {
  if (raw is! Map) return const <String, String>{};
  final Map<String, String> out = <String, String>{};
  raw.forEach((Object? k, Object? v) {
    if (k is String && v is String) {
      final String trimmed = v.trim();
      if (trimmed.isNotEmpty) out[k] = trimmed;
    }
  });
  return out;
}
