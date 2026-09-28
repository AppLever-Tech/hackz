import { Timestamp } from 'firebase-admin/firestore';
import {
  EVENT_ENTITLEMENT_STATUS_PENDING,
  eventEntitlementDocId,
  initialEventEntitlementFields,
  isPerEventCommercialPlan,
  normalizeEventEntitlementRequest,
  ORG_COMMERCIAL_PLAN_PER_EVENT,
  readEntitlementStatus,
} from './event-entitlement.js';
import { alignTenantCommercialAccess } from './event-payment-readiness.js';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { tenantApp, tenantAuth, tenantFirestore, controlPlaneFirestore } from './firebase-apps.js';
import { readOrganisationCommercialPlan } from './organisation-plan.js';
import {
  firestoreUserLookup,
  isDepartmentAdmin,
  loadTenantUserProfile,
  profileOrganisationId,
} from './tenant-operator.js';
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import {
  HKZ_EVENT_ENTITLEMENTS,
  type EventEntitlementRequest,
  type EventEntitlementResult,
} from './types.js';

function isAlreadyExists(error: unknown): boolean {
  if (error == null || typeof error !== 'object') return false;
  const code = 'code' in error ? String(error.code) : '';
  return code === 'already-exists' || code === '6' || code.includes('ALREADY_EXISTS');
}

async function assertTenantDepartmentAdmin(
  idToken: string,
  organisationId: string,
): Promise<void> {
  if (idToken.trim().length === 0) {
    throw new ProvisionError(
      'UNAUTHORIZED',
      'Sign in as a Department Admin to register event access.',
    );
  }

  const tenant = await resolveActiveTenantByOrganisationId(organisationId);
  const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);

  let decoded;
  try {
    decoded = await tenantAuth(app).verifyIdToken(idToken);
  } catch {
    throw new ProvisionError(
      'UNAUTHORIZED',
      'Sign in as a Department Admin to register event access.',
    );
  }

  let data;
  try {
    data = await loadTenantUserProfile(firestoreUserLookup(tenantFirestore(app)), decoded);
  } catch (error) {
    throw new ProvisionError(
      'PROVISIONING_NOT_AUTHORIZED',
      isPermissionDenied(error)
        ? 'The college must authorize the Hackz provisioning identity, then Validate authorization.'
        : 'Unable to read the tenant user profile.',
    );
  }

  if (!isDepartmentAdmin(data) || profileOrganisationId(data) !== organisationId) {
    throw new ProvisionError(
      'UNAUTHORIZED',
      'Only a Department Admin can register event access.',
    );
  }
}

async function alignPendingTenantAccess(organisationId: string, eventId: string): Promise<void> {
  try {
    await alignTenantCommercialAccess({
      organisationId,
      eventId,
      licensingStatus: EVENT_ENTITLEMENT_STATUS_PENDING,
    });
  } catch {
    // Tenant align is best-effort. Control Plane entitlement remains the source of truth.
  }
}

export async function registerEventEntitlement(input: EventEntitlementRequest & { idToken: string }): Promise<EventEntitlementResult> {
  const normalized = normalizeEventEntitlementRequest(input);
  const commercialPlan = await readOrganisationCommercialPlan(normalized.organisationId);
  if (!isPerEventCommercialPlan(commercialPlan)) {
    return {
      ok: true,
      skipped: true,
      existing: false,
      entitlementId: '',
      organisationId: normalized.organisationId,
      eventId: normalized.eventId,
    };
  }

  await assertTenantDepartmentAdmin(input.idToken, normalized.organisationId);

  const entitlementId = eventEntitlementDocId(normalized.organisationId, normalized.eventId);
  const ref = controlPlaneFirestore().collection(HKZ_EVENT_ENTITLEMENTS).doc(entitlementId);

  try {
    const existing = await ref.get();
    if (existing.exists) {
      if (readEntitlementStatus(existing.data() ?? {}) === EVENT_ENTITLEMENT_STATUS_PENDING) {
        await alignPendingTenantAccess(normalized.organisationId, normalized.eventId);
      }
      return {
        ok: true,
        skipped: false,
        existing: true,
        entitlementId,
        organisationId: normalized.organisationId,
        eventId: normalized.eventId,
      };
    }
  } catch (error) {
    throw new ProvisionError(
      'CONTROL_PLANE_UNAVAILABLE',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot read Control Plane event entitlements.'
        : 'Unable to read Control Plane event entitlements.',
    );
  }

  const now = Timestamp.now();
  try {
    await ref.create({
      ...initialEventEntitlementFields(normalized, ORG_COMMERCIAL_PLAN_PER_EVENT),
      createdAt: now,
      updatedAt: now,
    });
  } catch (error) {
    if (isAlreadyExists(error)) {
      try {
        const raced = await ref.get();
        if (readEntitlementStatus(raced.data() ?? {}) === EVENT_ENTITLEMENT_STATUS_PENDING) {
          await alignPendingTenantAccess(normalized.organisationId, normalized.eventId);
        }
      } catch {
        // Existing entitlement is enough. Tenant align retries on the next open.
      }
      return {
        ok: true,
        skipped: false,
        existing: true,
        entitlementId,
        organisationId: normalized.organisationId,
        eventId: normalized.eventId,
      };
    }
    throw new ProvisionError(
      'WRITE_FAILED',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot write Control Plane event entitlements.'
        : 'Unable to register event access.',
    );
  }

  await alignPendingTenantAccess(normalized.organisationId, normalized.eventId);

  return {
    ok: true,
    skipped: false,
    existing: false,
    entitlementId,
    organisationId: normalized.organisationId,
    eventId: normalized.eventId,
  };
}
