import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/organization/models/enums/organization_commercial_plan.dart';
import 'package:hackz/features/organization/models/enums/organization_type.dart';
import 'package:hackz/features/organization/models/organization_model.dart';
import 'package:hackz/features/sysadmin/onboarding/models/event_entitlement.dart';
import 'package:hackz/features/sysadmin/onboarding/models/organisation_event_commercial_item.dart';

void main() {
  EventEntitlement entitlement({
    String? entitlementStatus,
    String? status,
    String paymentStatus = 'pending',
    String? commercialPlan,
    String? paymentMode,
  }) {
    return EventEntitlement.fromMap(
      'org-1_evt1',
      <String, dynamic>{
        'orgId': 'org-1',
        'eventId': 'evt1',
        'eventName': 'Spring Ideathon',
        'eventType': 'ideathon',
        if (entitlementStatus != null) 'entitlementStatus': entitlementStatus,
        if (status != null) 'status': status,
        if (commercialPlan != null) 'commercialPlan': commercialPlan,
        if (paymentMode != null) 'paymentMode': paymentMode,
        'paymentStatus': paymentStatus,
      },
    );
  }

  test('display state is Pending / Ready for Activation / Enabled / Disabled', () {
    expect(entitlement().displayState, EventEntitlementDisplayState.pending);
    expect(entitlement().displayState.label, 'Payment Pending');
    expect(
      entitlement(paymentStatus: 'paid').displayState,
      EventEntitlementDisplayState.readyForActivation,
    );
    expect(
      entitlement(paymentStatus: 'paid').displayState.label,
      'Ready for Activation',
    );
    expect(
      entitlement(entitlementStatus: 'enabled').displayState,
      EventEntitlementDisplayState.enabled,
    );
    expect(
      entitlement(entitlementStatus: 'disabled').displayState,
      EventEntitlementDisplayState.disabled,
    );
  });

  test('activate requires Control Plane payment received, not tenant idea payments', () {
    expect(entitlement().canActivate, isFalse);
    expect(entitlement().canRecordPayment, isTrue);
    expect(entitlement(paymentStatus: 'paid').canActivate, isTrue);
    expect(entitlement(paymentStatus: 'paid').canRecordPayment, isFalse);
    expect(entitlement(paymentStatus: 'unpaid').canActivate, isFalse);
    expect(
      entitlement(entitlementStatus: 'enabled', paymentStatus: 'paid').canActivate,
      isFalse,
    );
    expect(
      entitlement(entitlementStatus: 'disabled', paymentStatus: 'paid').canActivate,
      isTrue,
    );
    expect(entitlement(entitlementStatus: 'disabled').canActivate, isFalse);
    expect(entitlement().canDisable, isTrue);
    expect(entitlement(entitlementStatus: 'disabled').canDisable, isFalse);
  });

  test('fromMap reads entitlementStatus and existing status field', () {
    expect(
      entitlement(status: 'enabled').entitlementStatus,
      EventEntitlementStatus.enabled,
    );
    expect(
      entitlement(entitlementStatus: 'disabled', status: 'enabled').entitlementStatus,
      EventEntitlementStatus.disabled,
    );
    expect(
      entitlement(commercialPlan: 'PER_EVENT').commercialPlan,
      OrganizationCommercialPlan.perEvent,
    );
    expect(
      entitlement(paymentMode: 'perEvent').commercialPlan,
      OrganizationCommercialPlan.perEvent,
    );
  });

  test('licensing status is separate from event lifecycle values', () {
    expect(EventEntitlementStatus.fromWire('scheduled'), EventEntitlementStatus.pending);
    expect(EventEntitlementStatus.fromWire('inProgress'), EventEntitlementStatus.pending);
    expect(EventEntitlementStatus.fromWire('enabled').wireValue, 'enabled');
  });

  test('PER_EVENT commercial row uses derived ready-for-activation', () {
    final OrganisationEventCommercialItem pending =
        OrganisationEventCommercialItem.fromEntitlement(entitlement());
    expect(pending.accessLabel, 'Payment Pending');
    expect(pending.canActivate, isFalse);
    expect(pending.canRecordPayment, isTrue);

    final OrganisationEventCommercialItem ready =
        OrganisationEventCommercialItem.fromEntitlement(entitlement(paymentStatus: 'paid'));
    expect(ready.accessLabel, 'Ready for Activation');
    expect(ready.tone, EventCommercialAccessTone.readyForActivation);
    expect(ready.canActivate, isTrue);
  });

  test('ANNUAL events are automatically enabled while the contract is valid', () {
    final OrganizationModel annual = OrganizationModel(
      id: 'org-1',
      name: 'Alpha College',
      type: OrganizationType.college,
      address: '1 Road',
      website: 'https://alpha.edu',
      contact: '999',
      createdAt: DateTime.utc(2026, 1, 1),
      commercialPlan: OrganizationCommercialPlan.annual,
      validFrom: DateTime(2026, 1, 1),
      validUntil: DateTime(2026, 12, 31),
    );
    const TenantEventCatalogEntry event = TenantEventCatalogEntry(
      eventId: 'evt1',
      eventName: 'Spring',
      eventType: 'ideathon',
    );
    final OrganisationEventCommercialItem valid = OrganisationEventCommercialItem.fromCatalog(
      organization: annual,
      event: event,
      now: DateTime(2026, 6, 1),
    );
    expect(valid.accessLabel, OrganisationEventCommercialItem.annualEnabledReason);
    expect(valid.canActivate, isFalse);
    expect(valid.canDisable, isFalse);
    expect(valid.canRecordPayment, isFalse);
    expect(valid.paymentLabel, OrganisationEventCommercialItem.paymentNotRequired);

    final OrganisationEventCommercialItem expired = OrganisationEventCommercialItem.fromCatalog(
      organization: annual.copyWith(validUntil: DateTime(2025, 12, 31)),
      event: event,
      now: DateTime(2026, 6, 1),
    );
    expect(expired.accessLabel, OrganisationEventCommercialItem.annualInvalidReason);
    expect(expired.canActivate, isFalse);
  });

  test('PER_IDEA events are governed by the organisation plan', () {
    final OrganizationModel perIdea = OrganizationModel(
      id: 'org-1',
      name: 'Alpha College',
      type: OrganizationType.college,
      address: '1 Road',
      website: 'https://alpha.edu',
      contact: '999',
      createdAt: DateTime.utc(2026, 1, 1),
    );
    final OrganisationEventCommercialItem row = OrganisationEventCommercialItem.fromCatalog(
      organization: perIdea,
      event: const TenantEventCatalogEntry(
        eventId: 'evt1',
        eventName: 'Spring',
        eventType: 'hackathon',
      ),
    );
    expect(row.accessLabel, OrganisationEventCommercialItem.perIdeaReason);
    expect(row.commercialPlan, OrganizationCommercialPlan.perIdea);
    expect(row.canActivate, isFalse);
    expect(row.isPerEvent, isFalse);
  });
}
