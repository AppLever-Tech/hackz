import { Timestamp } from 'firebase-admin/firestore';
import {
  eventEntitlementDocId,
  isEventCommercialPaymentReceived,
  isSameLicensingStatus,
  normalizeSetEventEntitlementStatusRequest,
  readEntitlementStatus,
  tenantCommercialAccessStatus,
} from './event-entitlement.js';
import { isNotFound, isPermissionDenied, ProvisionError } from './errors.js';
import { tenantApp, tenantFirestore, controlPlaneFirestore } from './firebase-apps.js';
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import {
  HKZ_EVENT_ENTITLEMENTS,
  HKZ_IDEATHONS,
  type SetEventEntitlementStatusRequest,
  type SetEventEntitlementStatusResult,
} from './types.js';

export async function setEventEntitlementStatus(
  input: SetEventEntitlementStatusRequest,
): Promise<SetEventEntitlementStatusResult> {
  const normalized = normalizeSetEventEntitlementStatusRequest(input);
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

  const data = existing.data() ?? {};
  const currentStatus = readEntitlementStatus(data);
  const unchanged = isSameLicensingStatus(currentStatus, normalized.status);
  if (normalized.status === 'enabled' && !unchanged) {
    if (!isEventCommercialPaymentReceived(String(data.paymentStatus ?? ''))) {
      throw new ProvisionError(
        'INVALID_INPUT',
        'Record the agreed event commercial payment before activating.',
      );
    }
  }

  const tenant = await resolveActiveTenantByOrganisationId(normalized.organisationId);
  const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
  const eventRef = tenantFirestore(app).collection(HKZ_IDEATHONS).doc(normalized.eventId);

  try {
    const eventSnap = await eventRef.get();
    if (!eventSnap.exists) {
      throw new ProvisionError('WRITE_FAILED', 'The tenant event was not found.');
    }
  } catch (error) {
    if (error instanceof ProvisionError) throw error;
    throw new ProvisionError(
      'PROVISIONING_NOT_AUTHORIZED',
      isPermissionDenied(error)
        ? 'The college must authorize the Hackz provisioning identity, then Validate authorization.'
        : 'Unable to read the tenant event.',
    );
  }

  const now = Timestamp.now();
  const payload: Record<string, unknown> = {
    entitlementStatus: normalized.status,
    updatedAt: now,
  };
  if (!unchanged && normalized.status === 'enabled') {
    payload.activatedAt = now;
  }
  if (!unchanged && normalized.status === 'disabled') {
    payload.disabledAt = now;
  }

  try {
    await cpRef.set(payload, { merge: true });
  } catch (error) {
    throw new ProvisionError(
      'WRITE_FAILED',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot write Control Plane event entitlements.'
        : 'Unable to update event access.',
    );
  }

  try {
    await eventRef.update({
      commercialAccess: { status: tenantCommercialAccessStatus(normalized.status) },
      updatedAt: now,
    });
  } catch (error) {
    if (isNotFound(error)) {
      throw new ProvisionError('WRITE_FAILED', 'The tenant event was not found.');
    }
    throw new ProvisionError(
      'WRITE_FAILED',
      isPermissionDenied(error)
        ? 'The college must authorize the Hackz provisioning identity, then Validate authorization.'
        : 'Unable to update tenant event access.',
    );
  }

  return {
    ok: true,
    unchanged,
    entitlementId,
    organisationId: normalized.organisationId,
    eventId: normalized.eventId,
    status: normalized.status,
  };
}
