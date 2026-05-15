import 'package:cloud_firestore/cloud_firestore.dart';

enum IdeaStatus {
  pendingSubmission('pendingSubmission'),
  submitted('submitted'),
  underReview('underReview'),
  evaluated('evaluated'),
  approved('approved'),
  rejected('rejected');

  const IdeaStatus(this.value);
  final String value;

  static IdeaStatus fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    switch (normalized) {
      case 'pendingsubmission':
        return IdeaStatus.pendingSubmission;
      case 'underreview':
        return IdeaStatus.underReview;
      case 'evaluated':
        return IdeaStatus.evaluated;
      case 'approved':
        return IdeaStatus.approved;
      case 'rejected':
        return IdeaStatus.rejected;
      case 'submitted':
        return IdeaStatus.submitted;
      default:
        return IdeaStatus.submitted;
    }
  }
}

class IdeaModel {
  const IdeaModel({
    required this.ideaId,
    required this.problemId,
    required this.teamId,
    required this.ideaTitle,
    required this.description,
    required this.files,
    required this.status,
    required this.createdAt,
    required this.orgId,
    required this.departmentCode,
    required this.problemNumber,
    required this.problemTitle,
    required this.createdBy,
  });

  final String ideaId;
  final String problemId;
  final String teamId;
  final String ideaTitle;
  final String description;
  final List<String> files;
  final IdeaStatus status;
  final DateTime createdAt;
  final String orgId;
  final String departmentCode;
  final String problemNumber;
  final String problemTitle;
  final String createdBy;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ideaId': ideaId,
      'problemId': problemId,
      'teamId': teamId,
      'ideaTitle': ideaTitle,
      'description': description,
      'files': files,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'orgId': orgId,
      'departmentCode': departmentCode,
      'problemNumber': problemNumber,
      'problemTitle': problemTitle,
      'createdBy': createdBy,
    };
  }

  factory IdeaModel.fromMap(String ideaId, Map<String, dynamic> map) {
    return IdeaModel(
      ideaId: ((map['ideaId'] as String?) ?? '').trim().isNotEmpty ? (map['ideaId'] as String).trim() : ideaId,
      problemId: ((map['problemId'] as String?) ?? '').trim(),
      teamId: ((map['teamId'] as String?) ?? '').trim(),
      ideaTitle: ((map['ideaTitle'] as String?) ?? '').trim(),
      description: ((map['description'] as String?) ?? '').trim(),
      files: (map['files'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      status: IdeaStatus.fromRaw((map['status'] as String?) ?? 'pendingSubmission'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      problemNumber: ((map['problemNumber'] as String?) ?? '').trim(),
      problemTitle: ((map['problemTitle'] as String?) ?? '').trim(),
      createdBy: ((map['createdBy'] as String?) ?? '').trim(),
    );
  }
}
