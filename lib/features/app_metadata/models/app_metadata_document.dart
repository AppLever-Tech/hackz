import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_metadata_keys.dart';

class ProjectTeamMember {
  const ProjectTeamMember({
    required this.name,
    required this.designation,
  });

  final String name;
  final String designation;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name.trim(),
        'designation': designation.trim(),
      };

  factory ProjectTeamMember.fromMap(Map<String, dynamic> map) {
    return ProjectTeamMember(
      name: ((map['name'] as String?) ?? '').trim(),
      designation: ((map['designation'] as String?) ?? '').trim(),
    );
  }

  ProjectTeamMember copyWith({String? name, String? designation}) {
    return ProjectTeamMember(
      name: name ?? this.name,
      designation: designation ?? this.designation,
    );
  }
}

class AppInfoPayload {
  const AppInfoPayload({
    required this.version,
    required this.buildNumber,
    this.releaseNotes = '',
    this.additionalInfo = '',
  });

  final String version;
  final String buildNumber;
  final String releaseNotes;
  final String additionalInfo;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'version': version.trim(),
        'buildNumber': buildNumber.trim(),
        'releaseNotes': releaseNotes.trim(),
        'additionalInfo': additionalInfo.trim(),
      };

  factory AppInfoPayload.fromMap(Map<String, dynamic> map) {
    return AppInfoPayload(
      version: ((map['version'] as String?) ?? '').trim(),
      buildNumber: ((map['buildNumber'] as String?) ?? '').trim(),
      releaseNotes: ((map['releaseNotes'] as String?) ?? '').trim(),
      additionalInfo: ((map['additionalInfo'] as String?) ?? '').trim(),
    );
  }

  AppInfoPayload copyWith({
    String? version,
    String? buildNumber,
    String? releaseNotes,
    String? additionalInfo,
  }) {
    return AppInfoPayload(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

/// Generic metadata document — extensible for future types (FAQ, release notes, etc.).
class AppMetadataDocument {
  const AppMetadataDocument({
    required this.id,
    required this.type,
    required this.title,
    this.body = '',
    this.members = const <ProjectTeamMember>[],
    this.appInfo = const AppInfoPayload(version: '', buildNumber: ''),
    this.updatedAt,
  });

  final String id;
  final AppMetadataType type;
  final String title;
  final String body;
  final List<ProjectTeamMember> members;
  final AppInfoPayload appInfo;
  final DateTime? updatedAt;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'type': type.value,
      'title': title.trim(),
      if (type == AppMetadataType.text) 'body': body.trim(),
      if (type == AppMetadataType.projectTeam)
        'members': members.map((ProjectTeamMember m) => m.toMap()).toList(growable: false),
      if (type == AppMetadataType.appInfo) ...appInfo.toMap(),
      'updatedAt': DateTime.now(),
    };
  }

  factory AppMetadataDocument.fromFirestore(String id, Map<String, dynamic> map) {
    final AppMetadataType type = AppMetadataType.fromRaw((map['type'] as String?) ?? 'text');
    final List<ProjectTeamMember> members = (map['members'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ProjectTeamMember.fromMap)
        .toList(growable: false);

    return AppMetadataDocument(
      id: id,
      type: type,
      title: ((map['title'] as String?) ?? '').trim(),
      body: ((map['body'] as String?) ?? '').trim(),
      members: members,
      appInfo: AppInfoPayload.fromMap(map),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  AppMetadataDocument copyWith({
    String? title,
    String? body,
    List<ProjectTeamMember>? members,
    AppInfoPayload? appInfo,
  }) {
    return AppMetadataDocument(
      id: id,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      members: members ?? this.members,
      appInfo: appInfo ?? this.appInfo,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _readDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
