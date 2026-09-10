import {
  computeEventPaymentReadiness,
  eventEntitlementDocId,
  normalizeEventEntitlementStatus,
  type EventPaymentReadiness,
} from './event-entitlement.js';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { tenantApp, tenantFirestore, controlPlaneFirestore } from './firebase-apps.js';
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import {
  HKZ_EVENT_ENTITLEMENTS,
  HKZ_IDEATHON_PARTICIPATIONS,
  HKZ_IDEATHONS,
  HKZ_PAYMENTS,
} from './types.js';

export async function loadEventPaymentReadiness(input: {
  organisationId: string;
  eventId: string;
}): Promise<EventPaymentReadiness> {
  const tenant = await resolveActiveTenantByOrganisationId(input.organisationId);
  const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
  const db = tenantFirestore(app);

  let paymentSnap;
  let participationSnap;
  try {
    [paymentSnap, participationSnap] = await Promise.all([
      db.collection(HKZ_PAYMENTS).where('ideathonId', '==', input.eventId).get(),
      db.collection(HKZ_IDEATHON_PARTICIPATIONS).where('ideathonId', '==', input.eventId).get(),
    ]);
  } catch (error) {
    throw new ProvisionError(
      'PROVISIONING_NOT_AUTHORIZED',
      isPermissionDenied(error)
        ? 'The college must authorize the Hackz provisioning identity, then Validate authorization.'
        : 'Unable to read tenant payment readiness.',
    );
  }

  return computeEventPaymentReadiness({
    eventId: input.eventId,
    payments: paymentSnap.docs.map((doc) => {
      const data = doc.data();
      return {
        ideaId: String(data.ideaId ?? '').trim(),
        status: String(data.status ?? '').trim(),
      };
    }),
    participations: participationSnap.docs.map((doc) => {
      const data = doc.data();
      return {
        ideaId: String(data.ideaId ?? '').trim(),
        paymentStatus: String(data.paymentStatus ?? '').trim(),
      };
    }),
  });
}

export function paymentReadinessFields(readiness: EventPaymentReadiness): Record<string, string | number | boolean> {
  return {
    paymentStatus: readiness.paymentStatus,
    lumpSumVerified: readiness.lumpSumVerified,
    ideaPaymentCount: readiness.ideaPaymentCount,
    ideaPaymentsVerified: readiness.ideaPaymentsVerified,
  };
}

export async function alignTenantCommercialAccess(input: {
  organisationId: string;
  eventId: string;
  licensingStatus: string;
}): Promise<void> {
  const tenant = await resolveActiveTenantByOrganisationId(input.organisationId);
  const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
  const status = normalizeEventEntitlementStatus(input.licensingStatus);
  try {
    await tenantFirestore(app)
      .collection(HKZ_IDEATHONS)
      .doc(input.eventId)
      .update({
        commercialAccess: { status },
      });
  } catch (error) {
    if (isPermissionDenied(error)) {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'The college must authorize the Hackz provisioning identity, then Validate authorization.',
      );
    }
  }
}

export function entitlementRef(organisationId: string, eventId: string) {
  return controlPlaneFirestore()
    .collection(HKZ_EVENT_ENTITLEMENTS)
    .doc(eventEntitlementDocId(organisationId, eventId));
}
