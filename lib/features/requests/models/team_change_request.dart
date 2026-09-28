import 'workflow_request.dart';
import 'workflow_request_type.dart';

/// Lightweight snapshot of a team member at request time. Names are
/// denormalized so the review pane never has to chase the user collection.
class TeamMemberSnapshot {
  const TeamMemberSnapshot({required this.userId, required this.displayName});

  final String userId;
  final String displayName;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'userId': userId,
        'displayName': displayName,
      };

  factory TeamMemberSnapshot.fromMap(Map<String, dynamic> map) {
    return TeamMemberSnapshot(
      userId: ((map['userId'] as String?) ?? '').trim(),
      displayName: ((map['displayName'] as String?) ?? '').trim(),
    );
  }

  static List<TeamMemberSnapshot> listFromRaw(dynamic raw) {
    if (raw is! List) return const <TeamMemberSnapshot>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TeamMemberSnapshot.fromMap)
        .where((TeamMemberSnapshot m) => m.userId.isNotEmpty)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> listToMap(Iterable<TeamMemberSnapshot> items) =>
      items.map((TeamMemberSnapshot m) => m.toMap()).toList(growable: false);
}

/// Typed view over the `payload` map of a [WorkflowRequest] when its type is
/// [WorkflowRequestType.teamChange].
class TeamChangePayload {
  const TeamChangePayload({
    required this.teamId,
    required this.teamName,
    required this.facultyId,
    required this.facultyName,
    required this.currentMembers,
    required this.proposedMembers,
    required this.hasEvaluation,
  });

  final String teamId;
  final String teamName;
  final String facultyId;
  final String facultyName;
  final List<TeamMemberSnapshot> currentMembers;
  final List<TeamMemberSnapshot> proposedMembers;
  final bool hasEvaluation;

  List<TeamMemberSnapshot> get addedMembers {
    final Set<String> current = currentMembers.map((m) => m.userId).toSet();
    return proposedMembers
        .where((TeamMemberSnapshot m) => !current.contains(m.userId))
        .toList(growable: false);
  }

  List<TeamMemberSnapshot> get removedMembers {
    final Set<String> proposed = proposedMembers.map((m) => m.userId).toSet();
    return currentMembers
        .where((TeamMemberSnapshot m) => !proposed.contains(m.userId))
        .toList(growable: false);
  }

  bool get hasChanges => addedMembers.isNotEmpty || removedMembers.isNotEmpty;

  String get changeSummary {
    final int added = addedMembers.length;
    final int removed = removedMembers.length;
    if (added == 0 && removed == 0) return 'No member changes';
    final List<String> parts = <String>[];
    if (added > 0) parts.add('+$added member${added == 1 ? '' : 's'}');
    if (removed > 0) parts.add('-$removed member${removed == 1 ? '' : 's'}');
    return parts.join(' · ');
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'teamId': teamId,
      'teamName': teamName,
      'facultyId': facultyId,
      'facultyName': facultyName,
      'currentMembers': TeamMemberSnapshot.listToMap(currentMembers),
      'proposedMembers': TeamMemberSnapshot.listToMap(proposedMembers),
      'addedMemberIds': addedMembers.map((m) => m.userId).toList(growable: false),
      'removedMemberIds': removedMembers.map((m) => m.userId).toList(growable: false),
      'hasEvaluation': hasEvaluation,
    };
  }

  factory TeamChangePayload.fromMap(Map<String, dynamic> map) {
    return TeamChangePayload(
      teamId: ((map['teamId'] as String?) ?? '').trim(),
      teamName: ((map['teamName'] as String?) ?? '').trim(),
      facultyId: ((map['facultyId'] as String?) ?? '').trim(),
      facultyName: ((map['facultyName'] as String?) ?? '').trim(),
      currentMembers: TeamMemberSnapshot.listFromRaw(map['currentMembers']),
      proposedMembers: TeamMemberSnapshot.listFromRaw(map['proposedMembers']),
      hasEvaluation: (map['hasEvaluation'] as bool?) ?? false,
    );
  }

  static TeamChangePayload? fromRequest(WorkflowRequest request) {
    if (request.type != WorkflowRequestType.teamChange) return null;
    return TeamChangePayload.fromMap(request.payload);
  }
}
