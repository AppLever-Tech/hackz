import '../../../events/models/event_kind.dart';
import '../../../organization/models/enums/organization_commercial_plan.dart';
import '../../../organization/models/organization_model.dart';
import '../../../organization/services/organisation_access.dart';
import 'event_entitlement.dart';

/// Minimal tenant event fields for SysAdmin commercial display. Not an event admin model.
class TenantEventCatalogEntry {
  const TenantEventCatalogEntry({
    required this.eventId,
    required this.eventName,
    required this.eventType,
    this.createdAt,
  });

  final String eventId;
  final String eventName;
  final String eventType;
  final DateTime? createdAt;
}

enum EventCommercialAccessTone {
  paymentPending,
  readyForActivation,
  enabled,
  disabled,
  governed,
}

/// One row in the SysAdmin organisation Events/Commercial Access list.
class OrganisationEventCommercialItem {
  const OrganisationEventCommercialItem({
    required this.eventId,
    required this.eventName,
    required this.eventType,
    required this.commercialPlan,
    required this.paymentLabel,
    required this.accessLabel,
    required this.tone,
    this.createdAt,
    this.entitlement,
  });

  final String eventId;
  final String eventName;
  final String eventType;
  final OrganizationCommercialPlan commercialPlan;
  final String paymentLabel;
  final String accessLabel;
  final EventCommercialAccessTone tone;
  final DateTime? createdAt;
  final EventEntitlement? entitlement;

  EventKind get eventKind => EventKind.fromWire(eventType);

  bool get isPerEvent => commercialPlan == OrganizationCommercialPlan.perEvent;

  EventEntitlementDisplayState? get perEventFilterState =>
      isPerEvent ? entitlement?.displayState : null;

  bool get canRecordPayment => entitlement?.canRecordPayment == true;
  bool get canActivate => entitlement?.canActivate == true;
  bool get canDisable => entitlement?.canDisable == true;

  static const String annualEnabledReason = 'Enabled by Annual Contract';
  static const String annualInvalidReason = 'Annual contract not valid';
  static const String perIdeaReason = 'Governed by Per idea plan';
  static const String paymentNotRequired = 'Not required';

  factory OrganisationEventCommercialItem.fromEntitlement(EventEntitlement entitlement) {
    return OrganisationEventCommercialItem(
      eventId: entitlement.eventId,
      eventName: entitlement.eventName,
      eventType: entitlement.eventType,
      commercialPlan: OrganizationCommercialPlan.perEvent,
      paymentLabel: entitlement.paymentSummary,
      accessLabel: entitlement.displayState.label,
      tone: switch (entitlement.displayState) {
        EventEntitlementDisplayState.pending => EventCommercialAccessTone.paymentPending,
        EventEntitlementDisplayState.readyForActivation => EventCommercialAccessTone.readyForActivation,
        EventEntitlementDisplayState.enabled => EventCommercialAccessTone.enabled,
        EventEntitlementDisplayState.disabled => EventCommercialAccessTone.disabled,
      },
      createdAt: entitlement.createdAt,
      entitlement: entitlement,
    );
  }

  factory OrganisationEventCommercialItem.fromCatalog({
    required OrganizationModel organization,
    required TenantEventCatalogEntry event,
    DateTime? now,
  }) {
    final OrganizationCommercialPlan plan = organization.commercialPlan;
    if (plan == OrganizationCommercialPlan.annual) {
      final bool usable = OrganisationAccess.isGranted(organization, now: now);
      return OrganisationEventCommercialItem(
        eventId: event.eventId,
        eventName: event.eventName,
        eventType: event.eventType,
        commercialPlan: plan,
        paymentLabel: paymentNotRequired,
        accessLabel: usable ? annualEnabledReason : annualInvalidReason,
        tone: usable ? EventCommercialAccessTone.enabled : EventCommercialAccessTone.disabled,
        createdAt: event.createdAt,
      );
    }
    return OrganisationEventCommercialItem(
      eventId: event.eventId,
      eventName: event.eventName,
      eventType: event.eventType,
      commercialPlan: OrganizationCommercialPlan.perIdea,
      paymentLabel: paymentNotRequired,
      accessLabel: perIdeaReason,
      tone: EventCommercialAccessTone.governed,
      createdAt: event.createdAt,
    );
  }
}
