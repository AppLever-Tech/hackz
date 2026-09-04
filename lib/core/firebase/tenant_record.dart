import 'package:cloud_firestore/cloud_firestore.dart';

/// Control Plane tenant status. Only [active] is routable.
enum TenantStatus {
  setup,
  active,
  inactive;

  String get wireValue => name;

  String get label {
    switch (this) {
      case TenantStatus.setup:
        return 'Setup';
      case TenantStatus.active:
        return 'Active';
      case TenantStatus.inactive:
        return 'Inactive';
    }
  }

  static TenantStatus? fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    for (final TenantStatus status in TenantStatus.values) {
      if (status.name == normalized) return status;
    }
    return null;
  }
}

/// Platform routing / onboarding record in `hkzTenants`. Not a college business model.
class TenantRecord {
  const TenantRecord({
    required this.tenantId,
    required this.organisationCode,
    required this.organisationName,
    required this.firebaseProjectId,
    required this.status,
    required this.createdAt,
    this.organisationId = '',
    this.firebaseValidated = false,
    this.hackzSetupComplete = false,
    this.initialAdminConfigured = false,
  });

  /// Internal immutable identifier. Never used in URLs or user-facing flows.
  final String tenantId;

  /// Human-facing routing key (`HKZ-XXXXXX`). Empty until activation.
  final String organisationCode;

  final String organisationName;

  /// Approved Firebase project id. Never accept user-supplied full config.
  final String firebaseProjectId;

  final TenantStatus status;
  final DateTime createdAt;

  /// Control Plane join to `hkzOrganizations/{id}` in the tenant project.
  final String organisationId;

  final bool firebaseValidated;
  final bool hackzSetupComplete;
  final bool initialAdminConfigured;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tenantId': tenantId,
      'organisationCode': organisationCode,
      'organisationName': organisationName,
      'firebaseProjectId': firebaseProjectId,
      'status': status.wireValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'organisationId': organisationId,
      'firebaseValidated': firebaseValidated,
      'hackzSetupComplete': hackzSetupComplete,
      'initialAdminConfigured': initialAdminConfigured,
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
      organisationId: (map['organisationId'] as String? ?? '').trim(),
      firebaseValidated: map['firebaseValidated'] == true,
      hackzSetupComplete: map['hackzSetupComplete'] == true,
      initialAdminConfigured: map['initialAdminConfigured'] == true,
    );
  }

  TenantRecord copyWith({
    String? tenantId,
    String? organisationCode,
    String? organisationName,
    String? firebaseProjectId,
    TenantStatus? status,
    DateTime? createdAt,
    String? organisationId,
    bool? firebaseValidated,
    bool? hackzSetupComplete,
    bool? initialAdminConfigured,
  }) {
    return TenantRecord(
      tenantId: tenantId ?? this.tenantId,
      organisationCode: organisationCode ?? this.organisationCode,
      organisationName: organisationName ?? this.organisationName,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      organisationId: organisationId ?? this.organisationId,
      firebaseValidated: firebaseValidated ?? this.firebaseValidated,
      hackzSetupComplete: hackzSetupComplete ?? this.hackzSetupComplete,
      initialAdminConfigured: initialAdminConfigured ?? this.initialAdminConfigured,
    );
  }
}
