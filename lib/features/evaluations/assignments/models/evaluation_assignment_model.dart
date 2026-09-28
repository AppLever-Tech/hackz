import 'package:cloud_firestore/cloud_firestore.dart';

enum EvaluationAssignmentStatus {
  active('active'),
  removed('removed');

  const EvaluationAssignmentStatus(this.value);
  final String value;

  static EvaluationAssignmentStatus fromRaw(String raw) {
    final String normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'removed':
        return EvaluationAssignmentStatus.removed;
      case 'active':
      default:
        return EvaluationAssignmentStatus.active;
    }
  }
}

class EvaluationAssignmentModel {
  const EvaluationAssignmentModel({
    required this.assignmentId,
    required this.orgId,
    required this.problemId,
    required this.ideaId,
    required this.judgeId,
    required this.status,
    required this.assignedBy,
    required this.assignedAt,
    required this.updatedAt,
    this.ideathonId = '',
  });

  final String assignmentId;
  final String orgId;
  final String problemId;
  final String ideaId;
  final String judgeId;
  final EvaluationAssignmentStatus status;
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime updatedAt;
  final String ideathonId;

  bool get isActive => status == EvaluationAssignmentStatus.active;
  bool get isIdeathonAssignment => ideathonId.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'assignmentId': assignmentId,
      'orgId': orgId,
      'problemId': problemId,
      'ideaId': ideaId,
      'judgeId': judgeId,
      'status': status.value,
      'assignedBy': assignedBy,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (ideathonId.trim().isNotEmpty) 'ideathonId': ideathonId.trim(),
    };
  }

  factory EvaluationAssignmentModel.fromMap(String id, Map<String, dynamic> map) {
    return EvaluationAssignmentModel(
      assignmentId: ((map['assignmentId'] as String?) ?? '').trim().isNotEmpty
          ? ((map['assignmentId'] as String?) ?? '').trim()
          : id,
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      problemId: ((map['problemId'] as String?) ?? '').trim(),
      ideaId: ((map['ideaId'] as String?) ?? '').trim(),
      judgeId: ((map['judgeId'] as String?) ?? '').trim(),
      status: EvaluationAssignmentStatus.fromRaw((map['status'] as String?) ?? 'active'),
      assignedBy: ((map['assignedBy'] as String?) ?? '').trim(),
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ideathonId: ((map['ideathonId'] as String?) ?? '').trim(),
    );
  }
}
