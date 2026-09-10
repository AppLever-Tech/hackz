import 'package:cloud_firestore/cloud_firestore.dart';

/// Control Plane event licensing metadata. Not a tenant event and not lifecycle.
enum EventEntitlementStatus {
  pending,
  enabled,
  disabled;

  String get wireValue => name;

  static EventEntitlementStatus fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    if (normalized == enabled.wireValue) return enabled;
    if (normalized == disabled.wireValue) return disabled;
    return pending;
  }
}

enum EventEntitlementPaymentStatus {
  unpaid,
  pending,
  paid;

  String get wireValue => name;

  static EventEntitlementPaymentStatus fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    if (normalized == paid.wireValue) return paid;
    if (normalized == pending.wireValue) return pending;
    return unpaid;
  }
}

enum EventEntitlementDisplayState {
  pending,
  readyForActivation,
  enabled,
  disabled;

  String get label => switch (this) {
        EventEntitlementDisplayState.pending => 'Pending',
        EventEntitlementDisplayState.readyForActivation => 'Ready for Activation',
        EventEntitlementDisplayState.enabled => 'Enabled',
        EventEntitlementDisplayState.disabled => 'Disabled',
      };
}

class EventEntitlement {
  const EventEntitlement({
    required this.id,
    required this.orgId,
    required this.eventId,
    required this.eventName,
    required this.eventType,
    required this.status,
    required this.paymentMode,
    required this.paymentStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orgId;
  final String eventId;
  final String eventName;
  final String eventType;
  final EventEntitlementStatus status;
  final String paymentMode;
  final EventEntitlementPaymentStatus paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EventEntitlementDisplayState get displayState {
    if (status == EventEntitlementStatus.enabled) return EventEntitlementDisplayState.enabled;
    if (status == EventEntitlementStatus.disabled) return EventEntitlementDisplayState.disabled;
    if (paymentStatus == EventEntitlementPaymentStatus.paid) {
      return EventEntitlementDisplayState.readyForActivation;
    }
    return EventEntitlementDisplayState.pending;
  }

  bool get canActivate => status != EventEntitlementStatus.enabled;
  bool get canDisable => status != EventEntitlementStatus.disabled;

  factory EventEntitlement.fromMap(String id, Map<String, dynamic> map) {
    return EventEntitlement(
      id: id,
      orgId: (map['orgId'] as String? ?? '').trim(),
      eventId: (map['eventId'] as String? ?? '').trim(),
      eventName: (map['eventName'] as String? ?? '').trim(),
      eventType: (map['eventType'] as String? ?? '').trim(),
      status: EventEntitlementStatus.fromWire(map['status']),
      paymentMode: (map['paymentMode'] as String? ?? 'perEvent').trim(),
      paymentStatus: EventEntitlementPaymentStatus.fromWire(map['paymentStatus']),
      createdAt: _optionalDate(map['createdAt']),
      updatedAt: _optionalDate(map['updatedAt']),
    );
  }

  static DateTime? _optionalDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
