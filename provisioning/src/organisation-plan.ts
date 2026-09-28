import { isPerEventCommercialPlan } from './event-entitlement.js';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneFirestore } from './firebase-apps.js';
import { HKZ_ORGANIZATIONS } from './types.js';

export async function readOrganisationCommercialPlan(organisationId: string): Promise<string> {
  let doc;
  try {
    doc = await controlPlaneFirestore().collection(HKZ_ORGANIZATIONS).doc(organisationId).get();
  } catch (error) {
    throw new ProvisionError(
      'CONTROL_PLANE_UNAVAILABLE',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot read Control Plane organisations.'
        : 'Unable to read Control Plane organisation commercial plan.',
    );
  }
  const data = doc.data() ?? {};
  return String(data.commercialPlan ?? data.accessMode ?? '').trim();
}

export async function assertOrganisationIsPerEvent(organisationId: string): Promise<void> {
  const plan = await readOrganisationCommercialPlan(organisationId);
  if (!isPerEventCommercialPlan(plan)) {
    throw new ProvisionError(
      'INVALID_INPUT',
      'Event entitlement actions apply only to organisations on the Per event commercial plan.',
    );
  }
}
