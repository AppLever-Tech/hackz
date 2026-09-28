import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../organization/models/enums/organization_commercial_plan.dart';

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
  pending,
  paid;

  String get wireValue => name;

  String get label => this == EventEntitlementPaymentStatus.paid ? 'Payment received' : 'Payment pending';

  static EventEntitlementPaymentStatus fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    if (normalized == paid.wireValue) return paid;
    return pending;
  }
}

enum EventEntitlementDisplayState {
  pending,
  readyForActivation,
  enabled,
  disabled;

  String get label => switch (this) {
        EventEntitlementDisplayState.pending => 'Payment Pending',
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
    required this.entitlementStatus,
    required this.commercialPlan,
    required this.paymentStatus,
    this.createdAt,
    this.updatedAt,
    this.activatedAt,
    this.disabledAt,
    this.paymentReceivedAt,
  });

  final String id;
  final String orgId;
  final String eventId;
  final String eventName;
  final String eventType;
  final EventEntitlementStatus entitlementStatus;
  final OrganizationCommercialPlan commercialPlan;
  final EventEntitlementPaymentStatus paymentStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? activatedAt;
  final DateTime? disabledAt;
  final DateTime? paymentReceivedAt;

  bool get paymentReceived => paymentStatus == EventEntitlementPaymentStatus.paid;

  String get paymentSummary => paymentStatus.label;

  EventEntitlementDisplayState get displayState {
    if (entitlementStatus == EventEntitlementStatus.enabled) {
      return EventEntitlementDisplayState.enabled;
    }
    if (entitlementStatus == EventEntitlementStatus.disabled) {
      return EventEntitlementDisplayState.disabled;
    }
    if (paymentReceived) return EventEntitlementDisplayState.readyForActivation;
    return EventEntitlementDisplayState.pending;
  }

  bool get canRecordPayment => !paymentReceived;
  bool get canActivate => entitlementStatus != EventEntitlementStatus.enabled && paymentReceived;
  bool get canDisable => entitlementStatus != EventEntitlementStatus.disabled;

  factory EventEntitlement.fromMap(String id, Map<String, dynamic> map) {
    return EventEntitlement(
      id: id,
      orgId: (map['orgId'] as String? ?? '').trim(),
      eventId: (map['eventId'] as String? ?? '').trim(),
      eventName: (map['eventName'] as String? ?? '').trim(),
      eventType: (map['eventType'] as String? ?? map['eventTemplate'] as String? ?? '').trim(),
      entitlementStatus: EventEntitlementStatus.fromWire(
        map['entitlementStatus'] ?? map['status'],
      ),
      commercialPlan: OrganizationCommercialPlan.fromWire(
        map['commercialPlan'] ?? map['paymentMode'] ?? OrganizationCommercialPlan.perEvent.wireValue,
      ),
      paymentStatus: EventEntitlementPaymentStatus.fromWire(map['paymentStatus']),
      createdAt: _optionalDate(map['createdAt']),
      updatedAt: _optionalDate(map['updatedAt']),
      activatedAt: _optionalDate(map['activatedAt']),
      disabledAt: _optionalDate(map['disabledAt']),
      paymentReceivedAt: _optionalDate(map['paymentReceivedAt']),
    );
  }

  static DateTime? _optionalDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
