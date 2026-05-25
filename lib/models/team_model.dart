import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums/team_status.dart';

class TeamModel {
  const TeamModel({
    required this.teamId,
    required this.teamName,
    required this.mentorId,
    required this.studentIds,
    required this.orgId,
    required this.departmentCode,
    required this.status,
    required this.createdAt,
  });

  final String teamId;
  final String teamName;
  final String mentorId;
  final List<String> studentIds;
  final String orgId;
  final String departmentCode;
  final TeamStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'teamId': teamId,
      'teamName': teamName,
      'mentorId': mentorId,
      'studentIds': studentIds,
      'orgId': orgId,
      'departmentCode': departmentCode,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TeamModel.fromMap(String teamId, Map<String, dynamic> map) {
    return TeamModel(
      teamId: ((map['teamId'] as String?) ?? '').trim().isEmpty ? teamId : ((map['teamId'] as String?) ?? '').trim(),
      teamName: ((map['teamName'] as String?) ?? '').trim(),
      mentorId: ((map['mentorId'] as String?) ?? '').trim(),
      studentIds: (map['studentIds'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList(growable: false),
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      status: TeamStatus.fromRaw((map['status'] as String?) ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  TeamModel copyWith({
    String? teamId,
    String? teamName,
    String? mentorId,
    List<String>? studentIds,
    String? orgId,
    String? departmentCode,
    TeamStatus? status,
    DateTime? createdAt,
  }) {
    return TeamModel(
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      mentorId: mentorId ?? this.mentorId,
      studentIds: studentIds ?? this.studentIds,
      orgId: orgId ?? this.orgId,
      departmentCode: departmentCode ?? this.departmentCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
