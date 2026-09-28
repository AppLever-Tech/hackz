import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluationAssignmentGroupModel {
  const EvaluationAssignmentGroupModel({
    required this.groupId,
    required this.orgId,
    required this.problemId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String groupId;
  final String orgId;
  final String problemId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'groupId': groupId,
      'orgId': orgId,
      'problemId': problemId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory EvaluationAssignmentGroupModel.fromMap(String id, Map<String, dynamic> map) {
    return EvaluationAssignmentGroupModel(
      groupId: ((map['groupId'] as String?) ?? '').trim().isNotEmpty
          ? ((map['groupId'] as String?) ?? '').trim()
          : id,
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      problemId: ((map['problemId'] as String?) ?? '').trim(),
      createdBy: ((map['createdBy'] as String?) ?? '').trim(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
