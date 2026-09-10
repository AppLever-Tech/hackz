import assert from 'node:assert/strict';
import { test } from 'node:test';
import { ProvisionError } from './errors.js';
import {
  eventEntitlementDisplayState,
  eventEntitlementDocId,
  initialEventEntitlementFields,
  isPerEventAccessMode,
  isSameLicensingStatus,
  normalizeEventEntitlementRequest,
  normalizeSetEventEntitlementStatusRequest,
  tenantCommercialAccessStatus,
} from './event-entitlement.js';

test('eventEntitlementDocId is deterministic for orgId + eventId', () => {
  assert.equal(eventEntitlementDocId('org-1', 'evtA'), 'org-1_evtA');
  assert.equal(eventEntitlementDocId('org-1', 'evtA'), eventEntitlementDocId('org-1', 'evtA'));
  assert.notEqual(eventEntitlementDocId('org-1', 'evtA'), eventEntitlementDocId('org-1', 'evtB'));
  assert.notEqual(eventEntitlementDocId('org-1', 'evtA'), eventEntitlementDocId('org-2', 'evtA'));
});

test('normalizeEventEntitlementRequest trims identity fields', () => {
  const input = normalizeEventEntitlementRequest({
    organisationId: ' org-1 ',
    eventId: ' evt_1 ',
    eventName: '  Spring  Ideathon  ',
    eventType: 'ideathon',
  });
  assert.equal(input.organisationId, 'org-1');
  assert.equal(input.eventId, 'evt_1');
  assert.equal(input.eventName, 'Spring Ideathon');
  assert.equal(input.eventType, 'ideathon');
});

test('normalizeEventEntitlementRequest rejects missing and invalid fields', () => {
  assert.throws(
    () =>
      normalizeEventEntitlementRequest({
        organisationId: '',
        eventId: 'evt1',
        eventName: 'Spring',
        eventType: 'ideathon',
      }),
    (error: unknown) => error instanceof ProvisionError && error.code === 'INVALID_INPUT',
  );
  assert.throws(
    () =>
      normalizeEventEntitlementRequest({
        organisationId: 'org-1',
        eventId: 'evt/1',
        eventName: 'Spring',
        eventType: 'ideathon',
      }),
    (error: unknown) => error instanceof ProvisionError && error.code === 'INVALID_INPUT',
  );
  assert.throws(
    () =>
      normalizeEventEntitlementRequest({
        organisationId: 'org-1',
        eventId: 'evt1',
        eventName: 'Spring',
        eventType: 'workshop',
      }),
    (error: unknown) => error instanceof ProvisionError && error.code === 'INVALID_INPUT',
  );
});

test('isPerEventAccessMode skips non-perEvent organisations', () => {
  assert.equal(isPerEventAccessMode('perEvent'), true);
  assert.equal(isPerEventAccessMode(' perEvent '), true);
  assert.equal(isPerEventAccessMode('perIdea'), false);
  assert.equal(isPerEventAccessMode('subscription'), false);
  assert.equal(isPerEventAccessMode(''), false);
});

test('initialEventEntitlementFields stores only SysAdmin entitlement metadata', () => {
  const fields = initialEventEntitlementFields({
    organisationId: 'org-1',
    eventId: 'evt1',
    eventName: 'Spring Ideathon',
    eventType: 'hackathon',
  });
  assert.deepEqual(fields, {
    orgId: 'org-1',
    eventId: 'evt1',
    eventName: 'Spring Ideathon',
    eventType: 'hackathon',
    status: 'pending',
    paymentMode: 'perEvent',
    paymentStatus: 'unpaid',
  });
  assert.equal(Object.prototype.hasOwnProperty.call(fields, 'ideas'), false);
  assert.equal(Object.prototype.hasOwnProperty.call(fields, 'teams'), false);
  assert.equal(Object.prototype.hasOwnProperty.call(fields, 'users'), false);
});

test('display state is Pending / Ready for Activation / Enabled / Disabled', () => {
  assert.equal(
    eventEntitlementDisplayState({ status: 'pending', paymentStatus: 'unpaid' }),
    'pending',
  );
  assert.equal(
    eventEntitlementDisplayState({ status: 'pending', paymentStatus: 'paid' }),
    'readyForActivation',
  );
  assert.equal(
    eventEntitlementDisplayState({ status: 'enabled', paymentStatus: 'unpaid' }),
    'enabled',
  );
  assert.equal(
    eventEntitlementDisplayState({ status: 'disabled', paymentStatus: 'paid' }),
    'disabled',
  );
});

test('set-event-entitlement-status is idempotent and maps only commercialAccess', () => {
  const input = normalizeSetEventEntitlementStatusRequest({
    organisationId: ' org-1 ',
    eventId: ' evt1 ',
    status: ' Enabled ',
  });
  assert.equal(input.organisationId, 'org-1');
  assert.equal(input.eventId, 'evt1');
  assert.equal(input.status, 'enabled');
  assert.equal(eventEntitlementDocId(input.organisationId, input.eventId), 'org-1_evt1');
  assert.equal(isSameLicensingStatus('enabled', 'enabled'), true);
  assert.equal(isSameLicensingStatus('pending', 'enabled'), false);
  assert.equal(isSameLicensingStatus('disabled', 'disabled'), true);
  assert.equal(tenantCommercialAccessStatus('enabled'), 'enabled');
  assert.equal(tenantCommercialAccessStatus('disabled'), 'disabled');
  assert.throws(
    () =>
      normalizeSetEventEntitlementStatusRequest({
        organisationId: 'org-1',
        eventId: 'evt1',
        status: 'scheduled',
      }),
    (error: unknown) => error instanceof ProvisionError && error.code === 'INVALID_INPUT',
  );
});
