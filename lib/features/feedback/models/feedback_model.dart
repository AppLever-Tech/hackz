import 'package:cloud_firestore/cloud_firestore.dart';

import 'feedback_status.dart';
import 'feedback_type.dart';

class FeedbackModel {
  const FeedbackModel({
    required this.feedbackId,
    required this.organizationId,
    required this.organizationName,
    required this.departmentId,
    required this.submittedBy,
    required this.submittedByName,
    required this.role,
    required this.type,
    required this.title,
    required this.description,
    required this.screenshotUrl,
    required this.status,
    required this.internalNotes,
    required this.platform,
    required this.appVersion,
    required this.screenName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String feedbackId;
  final String organizationId;
  final String organizationName;
  final String departmentId;
  final String submittedBy;
  final String submittedByName;
  final String role;
  final FeedbackType type;
  final String title;
  final String description;
  final String? screenshotUrl;
  final FeedbackStatus status;
  final String internalNotes;
  final String platform;
  final String appVersion;
  final String screenName;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeedbackModel copyWith({
    String? organizationName,
    FeedbackStatus? status,
    String? internalNotes,
    String? screenshotUrl,
    DateTime? updatedAt,
  }) {
    return FeedbackModel(
      feedbackId: feedbackId,
      organizationId: organizationId,
      organizationName: organizationName ?? this.organizationName,
      departmentId: departmentId,
      submittedBy: submittedBy,
      submittedByName: submittedByName,
      role: role,
      type: type,
      title: title,
      description: description,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      status: status ?? this.status,
      internalNotes: internalNotes ?? this.internalNotes,
      platform: platform,
      appVersion: appVersion,
      screenName: screenName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Prefer stored org name; fall back to id.
  String get organizationDisplayName {
    final String name = organizationName.trim();
    if (name.isNotEmpty) return name;
    final String id = organizationId.trim();
    return id.isEmpty ? '—' : id;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'feedbackId': feedbackId,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'departmentId': departmentId,
      'submittedBy': submittedBy,
      'submittedByName': submittedByName,
      'role': role,
      'type': type.value,
      'title': title,
      'description': description,
      'screenshotUrl': screenshotUrl,
      'status': status.value,
      'internalNotes': internalNotes,
      'platform': platform,
      'appVersion': appVersion,
      'screenName': screenName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static FeedbackModel fromMap(Map<String, dynamic> data, {String? id}) {
    final String? rawUrl = (data['screenshotUrl'] as String?)?.trim();
    return FeedbackModel(
      feedbackId: ((data['feedbackId'] as String?) ?? id ?? '').trim(),
      organizationId: ((data['organizationId'] as String?) ?? '').trim(),
      organizationName: ((data['organizationName'] as String?) ?? '').trim(),
      departmentId: ((data['departmentId'] as String?) ?? '').trim(),
      submittedBy: ((data['submittedBy'] as String?) ?? '').trim(),
      submittedByName: ((data['submittedByName'] as String?) ?? '').trim(),
      role: ((data['role'] as String?) ?? '').trim(),
      type: FeedbackType.fromRaw((data['type'] as String?) ?? ''),
      title: ((data['title'] as String?) ?? '').trim(),
      description: ((data['description'] as String?) ?? '').trim(),
      screenshotUrl: (rawUrl == null || rawUrl.isEmpty) ? null : rawUrl,
      status: FeedbackStatus.fromRaw((data['status'] as String?) ?? ''),
      internalNotes: ((data['internalNotes'] as String?) ?? '').trim(),
      platform: ((data['platform'] as String?) ?? '').trim(),
      appVersion: ((data['appVersion'] as String?) ?? '').trim(),
      screenName: ((data['screenName'] as String?) ?? '').trim(),
      createdAt: _date(data['createdAt']) ?? DateTime.now(),
      updatedAt: _date(data['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _date(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
