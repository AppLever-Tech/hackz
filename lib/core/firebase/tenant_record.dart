import 'package:cloud_firestore/cloud_firestore.dart';

/// Control Plane tenant status. Only [active] is routable.
enum TenantStatus {
  setup,
  active,
  inactive;

  String get wireValue => name;

  static TenantStatus? fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    for (final TenantStatus status in TenantStatus.values) {
      if (status.name == normalized) return status;
    }
    return null;
  }
}

/// Platform routing record in `hkzTenants`. Not a college business model.
class TenantRecord {
  const TenantRecord({
    required this.tenantId,
    required this.organisationCode,
    required this.organisationName,
    required this.firebaseProjectId,
    required this.status,
    required this.createdAt,
  });

  /// Internal immutable identifier. Never used in URLs or user-facing flows.
  final String tenantId;

  /// Human-facing routing key (`HKZ-XXXXXX`).
  final String organisationCode;

  final String organisationName;

  /// Approved Firebase project id. Never accept user-supplied full config.
  final String firebaseProjectId;

  final TenantStatus status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tenantId': tenantId,
      'organisationCode': organisationCode,
      'organisationName': organisationName,
      'firebaseProjectId': firebaseProjectId,
      'status': status.wireValue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TenantRecord.fromMap(Map<String, dynamic> map) {
    final TenantStatus? status = TenantStatus.fromWire(map['status']);
    if (status == null) {
      throw FormatException('Invalid tenant status: ${map['status']}');
    }
    return TenantRecord(
      tenantId: (map['tenantId'] as String? ?? '').trim(),
      organisationCode: (map['organisationCode'] as String? ?? '').trim(),
      organisationName: (map['organisationName'] as String? ?? '').trim(),
      firebaseProjectId: (map['firebaseProjectId'] as String? ?? '').trim(),
      status: status,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
