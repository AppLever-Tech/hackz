import 'package:cloud_firestore/cloud_firestore.dart';

import 'ideathon_idea_snapshot.dart';
import 'ideathon_status.dart';

class IdeathonModel {
  const IdeathonModel({
    required this.ideathonId,
    required this.orgId,
    required this.name,
    required this.description,
    required this.departmentId,
    required this.eventDate,
    required this.status,
    required this.judgeIds,
    required this.coordinatorIds,
    required this.ideas,
    required this.evaluationTemplateId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String ideathonId;
  final String orgId;
  final String name;
  final String description;
  final String departmentId;
  final DateTime eventDate;
  final IdeathonStatus status;
  final List<String> judgeIds;
  final List<String> coordinatorIds;
  final List<IdeathonIdeaSnapshot> ideas;
  final String evaluationTemplateId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get ideaCount => ideas.length;
  int get judgeCount => judgeIds.length;
  int get coordinatorCount => coordinatorIds.length;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ideathonId': ideathonId,
      'orgId': orgId,
      'name': name,
      'description': description,
      'departmentId': departmentId,
      'eventDate': Timestamp.fromDate(eventDate),
      'status': status.value,
      'judgeIds': judgeIds,
      'coordinatorIds': coordinatorIds,
      'ideas': ideas.map((IdeathonIdeaSnapshot i) => i.toMap()).toList(growable: false),
      'evaluationTemplateId': evaluationTemplateId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory IdeathonModel.fromMap(String id, Map<String, dynamic> map) {
    final List<IdeathonIdeaSnapshot> ideaSnapshots = <IdeathonIdeaSnapshot>[];
    final dynamic rawIdeas = map['ideas'];
    if (rawIdeas is List) {
      for (final dynamic item in rawIdeas) {
        if (item is Map) {
          ideaSnapshots.add(IdeathonIdeaSnapshot.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return IdeathonModel(
      ideathonId: ((map['ideathonId'] as String?) ?? '').trim().isNotEmpty
          ? ((map['ideathonId'] as String?) ?? '').trim()
          : id,
      orgId: (map['orgId'] as String? ?? '').trim(),
      name: (map['name'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
      departmentId: (map['departmentId'] as String? ?? '').trim(),
      eventDate: (map['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: IdeathonStatus.fromRaw((map['status'] as String?) ?? 'draft'),
      judgeIds: _readStringList(map['judgeIds']),
      coordinatorIds: _readStringList(map['coordinatorIds']),
      ideas: ideaSnapshots,
      evaluationTemplateId: (map['evaluationTemplateId'] as String? ?? '').trim(),
      createdBy: (map['createdBy'] as String? ?? '').trim(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static List<String> _readStringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((dynamic e) => e.toString().trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
  }
}
