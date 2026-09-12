import { Timestamp } from 'firebase-admin/firestore';
import {
  EVENT_PAYMENT_STATUS_PAID,
  eventEntitlementDocId,
  isEventCommercialPaymentReceived,
  normalizeRecordEventEntitlementPaymentRequest,
} from './event-entitlement.js';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneFirestore } from './firebase-apps.js';
import { assertOrganisationIsPerEvent } from './organisation-plan.js';
import {
  HKZ_EVENT_ENTITLEMENTS,
  type RecordEventEntitlementPaymentRequest,
  type RecordEventEntitlementPaymentResult,
} from './types.js';

export async function recordEventEntitlementPayment(
  input: RecordEventEntitlementPaymentRequest,
): Promise<RecordEventEntitlementPaymentResult> {
  const normalized = normalizeRecordEventEntitlementPaymentRequest(input);
  await assertOrganisationIsPerEvent(normalized.organisationId);
  const entitlementId = eventEntitlementDocId(normalized.organisationId, normalized.eventId);
  const cpRef = controlPlaneFirestore().collection(HKZ_EVENT_ENTITLEMENTS).doc(entitlementId);

  let existing;
  try {
    existing = await cpRef.get();
  } catch (error) {
    throw new ProvisionError(
      'CONTROL_PLANE_UNAVAILABLE',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot read Control Plane event entitlements.'
        : 'Unable to read Control Plane event entitlements.',
    );
  }
  if (!existing.exists) {
    throw new ProvisionError('INVALID_INPUT', 'Event entitlement was not found.');
  }

  const currentPaymentStatus = String(existing.data()?.paymentStatus ?? '');
  const unchanged = isEventCommercialPaymentReceived(currentPaymentStatus);
  if (!unchanged) {
    const now = Timestamp.now();
    try {
      await cpRef.set(
        {
          paymentStatus: EVENT_PAYMENT_STATUS_PAID,
          paymentReceivedAt: now,
          updatedAt: now,
        },
        { merge: true },
      );
    } catch (error) {
      throw new ProvisionError(
        'WRITE_FAILED',
        isPermissionDenied(error)
          ? 'The provisioning identity cannot write Control Plane event entitlements.'
          : 'Unable to record event payment.',
      );
    }
  }

  return {
    ok: true,
    unchanged,
    entitlementId,
    organisationId: normalized.organisationId,
    eventId: normalized.eventId,
    paymentStatus: EVENT_PAYMENT_STATUS_PAID,
  };
}
