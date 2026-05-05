import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  const TeamModel({
    required this.teamId,
    required this.name,
    required this.facultyId,
    required this.studentIds,
    required this.problemId,
    required this.problemNumber,
    required this.problemTitle,
    required this.orgId,
    required this.departmentCode,
    required this.createdAt,
  });

  final String teamId;
  final String name;
  final String facultyId;
  final List<String> studentIds;
  final String problemId;
  final String problemNumber;
  final String problemTitle;
  final String orgId;
  final String departmentCode;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'teamId': teamId,
      'name': name,
      'facultyId': facultyId,
      'studentIds': studentIds,
      'problemId': problemId,
      'problemNumber': problemNumber,
      'problemTitle': problemTitle,
      'orgId': orgId,
      'departmentCode': departmentCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TeamModel.fromMap(String teamId, Map<String, dynamic> map) {
    return TeamModel(
      teamId: ((map['teamId'] as String?) ?? '').trim().isEmpty ? teamId : ((map['teamId'] as String?) ?? '').trim(),
      name: ((map['name'] as String?) ?? '').trim(),
      facultyId: ((map['facultyId'] as String?) ?? '').trim(),
      studentIds: (map['studentIds'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(growable: false),
      problemId: ((map['problemId'] as String?) ?? '').trim(),
      problemNumber: ((map['problemNumber'] as String?) ?? '').trim(),
      problemTitle: ((map['problemTitle'] as String?) ?? '').trim(),
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  TeamModel copyWith({
    String? teamId,
    String? name,
    String? facultyId,
    List<String>? studentIds,
    String? problemId,
    String? problemNumber,
    String? problemTitle,
    String? orgId,
    String? departmentCode,
    DateTime? createdAt,
  }) {
    return TeamModel(
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      facultyId: facultyId ?? this.facultyId,
      studentIds: studentIds ?? this.studentIds,
      problemId: problemId ?? this.problemId,
      problemNumber: problemNumber ?? this.problemNumber,
      problemTitle: problemTitle ?? this.problemTitle,
      orgId: orgId ?? this.orgId,
      departmentCode: departmentCode ?? this.departmentCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
