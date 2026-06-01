import 'package:cloud_firestore/cloud_firestore.dart';

import '../../organization/models/department_model.dart';
import 'enums/idea_status.dart';

export 'enums/idea_status.dart';

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
    required this.teamDepartmentCode,
    required this.problemDepartmentCode,
    required this.problemNumber,
    required this.problemTitle,
    required this.createdBy,
    this.gitRepositoryUrl = '',
    this.youtubeDemoUrl = '',
  });

  static const String fieldTeamDepartmentCode = 'teamDepartmentCode';
  static const String fieldProblemDepartmentCode = 'problemDepartmentCode';

  final String ideaId;
  final String problemId;
  final String teamId;
  final String ideaTitle;
  final String description;
  final List<String> files;
  final IdeaStatus status;
  final DateTime createdAt;
  final String orgId;
  final String teamDepartmentCode;
  final String problemDepartmentCode;
  final String problemNumber;
  final String problemTitle;
  final String createdBy;
  final String gitRepositoryUrl;
  final String youtubeDemoUrl;

  bool get hasGitRepository => gitRepositoryUrl.trim().isNotEmpty;
  bool get hasYoutubeDemo => youtubeDemoUrl.trim().isNotEmpty;
  bool get hasPresentationFiles => files.isNotEmpty;

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
      fieldTeamDepartmentCode: teamDepartmentCode,
      fieldProblemDepartmentCode: problemDepartmentCode,
      'problemNumber': problemNumber,
      'problemTitle': problemTitle,
      'createdBy': createdBy,
      'gitRepositoryUrl': gitRepositoryUrl.trim(),
      'youtubeDemoUrl': youtubeDemoUrl.trim(),
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
      teamDepartmentCode: DepartmentModel.resolveCode((map[fieldTeamDepartmentCode] as String?) ?? ''),
      problemDepartmentCode: DepartmentModel.resolveCode((map[fieldProblemDepartmentCode] as String?) ?? ''),
      problemNumber: ((map['problemNumber'] as String?) ?? '').trim(),
      problemTitle: ((map['problemTitle'] as String?) ?? '').trim(),
      createdBy: ((map['createdBy'] as String?) ?? '').trim(),
      gitRepositoryUrl: ((map['gitRepositoryUrl'] as String?) ?? '').trim(),
      youtubeDemoUrl: ((map['youtubeDemoUrl'] as String?) ?? '').trim(),
    );
  }
}
