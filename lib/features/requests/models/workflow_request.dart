import 'package:cloud_firestore/cloud_firestore.dart';

import 'workflow_request_type.dart';
import 'workflow_status.dart';

/// Generic approval request entity — the single Firestore shape used by every
/// request type (team change, payments, exceptions, ...).
///
/// Type-specific data lives in [payload] so the schema is forward compatible.
class WorkflowRequest {
  const WorkflowRequest({
    required this.requestId,
    required this.type,
    required this.status,
    required this.orgId,
    required this.departmentCode,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedAt,
    required this.title,
    required this.summary,
    required this.reason,
    required this.adminComments,
    required this.targetEntityType,
    required this.targetEntityId,
    required this.approvedBy,
    required this.approvedAt,
    required this.rejectedBy,
    required this.rejectedAt,
    required this.payload,
  });

  final String requestId;
  final WorkflowRequestType type;
  final WorkflowStatus status;
  final String orgId;
  final String departmentCode;
  final String requestedBy;
  final String requestedByName;
  final DateTime requestedAt;
  final String title;
  final String summary;
  final String reason;
  final String adminComments;
  final String targetEntityType;
  final String targetEntityId;
  final String approvedBy;
  final DateTime? approvedAt;
  final String rejectedBy;
  final DateTime? rejectedAt;
  final Map<String, dynamic> payload;

  DateTime get resolvedAt =>
      approvedAt ?? rejectedAt ?? requestedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'requestId': requestId,
      'type': type.value,
      'status': status.value,
      'orgId': orgId,
      'departmentCode': departmentCode,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'title': title,
      'summary': summary,
      'reason': reason,
      'adminComments': adminComments,
      'targetEntityType': targetEntityType,
      'targetEntityId': targetEntityId,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt == null ? null : Timestamp.fromDate(approvedAt!),
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt == null ? null : Timestamp.fromDate(rejectedAt!),
      'payload': payload,
    };
  }

  factory WorkflowRequest.fromMap(String id, Map<String, dynamic> map) {
    String str(String key) => ((map[key] as String?) ?? '').trim();
    DateTime? ts(String key) => (map[key] as Timestamp?)?.toDate();

    final Map<String, dynamic> payload =
        (map['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{});

    return WorkflowRequest(
      requestId: str('requestId').isEmpty ? id : str('requestId'),
      type: WorkflowRequestType.fromRaw(str('type')),
      status: WorkflowStatus.fromRaw(str('status')),
      orgId: str('orgId'),
      departmentCode: str('departmentCode').toUpperCase(),
      requestedBy: str('requestedBy'),
      requestedByName: str('requestedByName'),
      requestedAt: ts('requestedAt') ?? DateTime.now(),
      title: str('title'),
      summary: str('summary'),
      reason: str('reason'),
      adminComments: str('adminComments'),
      targetEntityType: str('targetEntityType'),
      targetEntityId: str('targetEntityId'),
      approvedBy: str('approvedBy'),
      approvedAt: ts('approvedAt'),
      rejectedBy: str('rejectedBy'),
      rejectedAt: ts('rejectedAt'),
      payload: payload,
    );
  }

  WorkflowRequest copyWith({
    WorkflowStatus? status,
    String? adminComments,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedBy,
    DateTime? rejectedAt,
    Map<String, dynamic>? payload,
  }) {
    return WorkflowRequest(
      requestId: requestId,
      type: type,
      status: status ?? this.status,
      orgId: orgId,
      departmentCode: departmentCode,
      requestedBy: requestedBy,
      requestedByName: requestedByName,
      requestedAt: requestedAt,
      title: title,
      summary: summary,
      reason: reason,
      adminComments: adminComments ?? this.adminComments,
      targetEntityType: targetEntityType,
      targetEntityId: targetEntityId,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      payload: payload ?? this.payload,
    );
  }
}
