import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/organization/models/enums/organization_commercial_plan.dart';
import 'package:hackz/features/sysadmin/onboarding/models/event_entitlement.dart';

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
    expect(entitlement().displayState.label, 'Pending');
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
}
