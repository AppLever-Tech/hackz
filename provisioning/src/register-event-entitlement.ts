import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
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
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import {
  DEPARTMENT_ADMIN_ROLE,
  HKZ_EVENT_ENTITLEMENTS,
  HKZ_USERS,
  type EventEntitlementRequest,
  type EventEntitlementResult,
} from './types.js';

function isAlreadyExists(error: unknown): boolean {
  if (error == null || typeof error !== 'object') return false;
  const code = 'code' in error ? String(error.code) : '';
  return code === 'already-exists' || code === '6' || code.includes('ALREADY_EXISTS');
}

function isDepartmentAdmin(data: DocumentData | undefined): boolean {
  if (data == null) return false;
  if (String(data.role ?? '').trim() === DEPARTMENT_ADMIN_ROLE) return true;
  const roles = data.roles;
  return Array.isArray(roles) && roles.some((role) => String(role).trim() === DEPARTMENT_ADMIN_ROLE);
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

  let uid = '';
  try {
    const decoded = await tenantAuth(app).verifyIdToken(idToken);
    uid = decoded.uid;
  } catch {
    throw new ProvisionError(
      'UNAUTHORIZED',
      'Sign in as a Department Admin to register event access.',
    );
  }

  let profile;
  try {
    profile = await tenantFirestore(app).collection(HKZ_USERS).doc(uid).get();
  } catch (error) {
    throw new ProvisionError(
      'PROVISIONING_NOT_AUTHORIZED',
      isPermissionDenied(error)
        ? 'The college must authorize the Hackz provisioning identity, then Validate authorization.'
        : 'Unable to read the tenant user profile.',
    );
  }

  const data = profile.data();
  if (!profile.exists || !isDepartmentAdmin(data)) {
    throw new ProvisionError(
      'UNAUTHORIZED',
      'Only a Department Admin can register event access.',
    );
  }
  const userOrgId = String(data?.orgId ?? '').trim();
  if (userOrgId !== organisationId) {
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
  await assertTenantDepartmentAdmin(input.idToken, normalized.organisationId);

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
