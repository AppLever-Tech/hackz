import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/sysadmin/onboarding/models/event_entitlement.dart';

void main() {
  EventEntitlement entitlement({
    String status = 'pending',
    String paymentStatus = 'unpaid',
    bool lumpSumVerified = false,
    int ideaPaymentCount = 0,
    int ideaPaymentsVerified = 0,
  }) {
    return EventEntitlement.fromMap(
      'org-1_evt1',
      <String, dynamic>{
        'orgId': 'org-1',
        'eventId': 'evt1',
        'eventName': 'Spring Ideathon',
        'eventType': 'ideathon',
        'status': status,
        'paymentMode': 'perEvent',
        'paymentStatus': paymentStatus,
        'lumpSumVerified': lumpSumVerified,
        'ideaPaymentCount': ideaPaymentCount,
        'ideaPaymentsVerified': ideaPaymentsVerified,
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
    expect(entitlement(status: 'enabled').displayState, EventEntitlementDisplayState.enabled);
    expect(entitlement(status: 'disabled').displayState, EventEntitlementDisplayState.disabled);
  });

  test('activate requires payment readiness', () {
    expect(entitlement().canActivate, isFalse);
    expect(entitlement(paymentStatus: 'paid').canActivate, isTrue);
    expect(entitlement(lumpSumVerified: true).canActivate, isTrue);
    expect(
      entitlement(ideaPaymentCount: 2, ideaPaymentsVerified: 2).canActivate,
      isTrue,
    );
    expect(
      entitlement(ideaPaymentCount: 2, ideaPaymentsVerified: 1).canActivate,
      isFalse,
    );
    expect(entitlement(status: 'enabled', paymentStatus: 'paid').canActivate, isFalse);
    expect(entitlement(status: 'disabled', paymentStatus: 'paid').canActivate, isTrue);
    expect(entitlement(status: 'disabled').canActivate, isFalse);
    expect(entitlement().canDisable, isTrue);
    expect(entitlement(status: 'disabled').canDisable, isFalse);
  });

  test('licensing status is separate from event lifecycle values', () {
    expect(EventEntitlementStatus.fromWire('scheduled'), EventEntitlementStatus.pending);
    expect(EventEntitlementStatus.fromWire('inProgress'), EventEntitlementStatus.pending);
    expect(EventEntitlementStatus.fromWire('enabled').wireValue, 'enabled');
  });
}
