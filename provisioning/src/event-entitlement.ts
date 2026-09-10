import { ProvisionError } from './errors.js';
import type { EventEntitlementRequest } from './types.js';

export const EVENT_ENTITLEMENT_STATUS_PENDING = 'pending';
export const EVENT_ENTITLEMENT_STATUS_ENABLED = 'enabled';
export const EVENT_ENTITLEMENT_STATUS_DISABLED = 'disabled';
export const EVENT_PAYMENT_MODE_PER_EVENT = 'perEvent';
export const EVENT_PAYMENT_STATUS_UNPAID = 'unpaid';
export const EVENT_PAYMENT_STATUS_PAID = 'paid';
export const ORG_ACCESS_MODE_PER_EVENT = 'perEvent';

export type EventEntitlementLicensingStatus = 'pending' | 'enabled' | 'disabled';
export type EventEntitlementActionStatus = 'enabled' | 'disabled';
export type EventEntitlementDisplayState = 'pending' | 'readyForActivation' | 'enabled' | 'disabled';

export function isPerEventAccessMode(accessMode: string): boolean {
  return accessMode.trim() === ORG_ACCESS_MODE_PER_EVENT;
}

const ALLOWED_EVENT_TYPES = new Set(['ideathon', 'hackathon', 'researchPaper']);
const ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
const MAX_EVENT_NAME = 200;

export type NormalizedEventEntitlementInput = {
  organisationId: string;
  eventId: string;
  eventName: string;
  eventType: string;
};

function required(value: string | undefined, label: string): string {
  const text = (value ?? '').trim();
  if (text.length === 0) {
    throw new ProvisionError('INVALID_INPUT', `${label} is required.`);
  }
  return text;
}

function requiredId(value: string | undefined, label: string): string {
  const text = required(value, label);
  if (!ID_PATTERN.test(text)) {
    throw new ProvisionError('INVALID_INPUT', `${label} is not valid.`);
  }
  return text;
}

/** Deterministic Control Plane document id so orgId+eventId retries cannot duplicate. */
export function eventEntitlementDocId(organisationId: string, eventId: string): string {
  return `${organisationId}_${eventId}`;
}

export function normalizeEventEntitlementRequest(
  input: EventEntitlementRequest,
): NormalizedEventEntitlementInput {
  const organisationId = requiredId(input.organisationId, 'organisationId');
  const eventId = requiredId(input.eventId, 'eventId');
  const eventName = required(input.eventName, 'eventName').replace(/\s+/g, ' ');
  if (eventName.length > MAX_EVENT_NAME) {
    throw new ProvisionError('INVALID_INPUT', 'eventName is too long.');
  }
  const eventType = required(input.eventType, 'eventType');
  if (!ALLOWED_EVENT_TYPES.has(eventType)) {
    throw new ProvisionError('INVALID_INPUT', 'eventType is not valid.');
  }
  return { organisationId, eventId, eventName, eventType };
}

export function normalizeEventEntitlementStatus(value: string): EventEntitlementLicensingStatus {
  const status = value.trim().toLowerCase();
  if (status === EVENT_ENTITLEMENT_STATUS_ENABLED) return 'enabled';
  if (status === EVENT_ENTITLEMENT_STATUS_DISABLED) return 'disabled';
  return 'pending';
}

export function eventEntitlementDisplayState(input: {
  status: string;
  paymentStatus: string;
}): EventEntitlementDisplayState {
  const status = normalizeEventEntitlementStatus(input.status);
  if (status === 'enabled') return 'enabled';
  if (status === 'disabled') return 'disabled';
  if (input.paymentStatus.trim().toLowerCase() === EVENT_PAYMENT_STATUS_PAID) {
    return 'readyForActivation';
  }
  return 'pending';
}

export function tenantCommercialAccessStatus(
  licensingStatus: EventEntitlementActionStatus,
): EventEntitlementActionStatus {
  return licensingStatus;
}

export type NormalizedSetEventEntitlementStatusInput = {
  organisationId: string;
  eventId: string;
  status: EventEntitlementActionStatus;
};

export function normalizeSetEventEntitlementStatusRequest(input: {
  organisationId: string;
  eventId: string;
  status: string;
}): NormalizedSetEventEntitlementStatusInput {
  const organisationId = requiredId(input.organisationId, 'organisationId');
  const eventId = requiredId(input.eventId, 'eventId');
  const status = input.status.trim().toLowerCase();
  if (status !== EVENT_ENTITLEMENT_STATUS_ENABLED && status !== EVENT_ENTITLEMENT_STATUS_DISABLED) {
    throw new ProvisionError('INVALID_INPUT', 'status must be enabled or disabled.');
  }
  return { organisationId, eventId, status };
}

export function isSameLicensingStatus(
  current: string,
  next: EventEntitlementActionStatus,
): boolean {
  return normalizeEventEntitlementStatus(current) === next;
}

export function initialEventEntitlementFields(input: NormalizedEventEntitlementInput): Record<string, string> {
  return {
    orgId: input.organisationId,
    eventId: input.eventId,
    eventName: input.eventName,
    eventType: input.eventType,
    status: EVENT_ENTITLEMENT_STATUS_PENDING,
    paymentMode: EVENT_PAYMENT_MODE_PER_EVENT,
    paymentStatus: EVENT_PAYMENT_STATUS_UNPAID,
  };
}
