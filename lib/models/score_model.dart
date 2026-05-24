import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String scoreId;
  final String ideaId;
  final String judgeId;
  final double score;
  final String feedback;
  final DateTime createdAt;
  final String orgId;
  final String departmentCode;

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
    );
  }
}
