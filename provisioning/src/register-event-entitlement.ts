import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import {
  eventEntitlementDocId,
  initialEventEntitlementFields,
  isPerEventAccessMode,
  normalizeEventEntitlementRequest,
} from './event-entitlement.js';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { tenantApp, tenantAuth, tenantFirestore, controlPlaneFirestore } from './firebase-apps.js';
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import {
  DEPARTMENT_ADMIN_ROLE,
  HKZ_EVENT_ENTITLEMENTS,
  HKZ_ORGANIZATIONS,
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

async function organisationAccessMode(organisationId: string): Promise<string> {
  let doc;
  try {
    doc = await controlPlaneFirestore().collection(HKZ_ORGANIZATIONS).doc(organisationId).get();
  } catch (error) {
    throw new ProvisionError(
      'CONTROL_PLANE_UNAVAILABLE',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot read Control Plane organisations.'
        : 'Unable to read Control Plane organisation access.',
    );
  }
  return String(doc.data()?.accessMode ?? '').trim();
}

export async function registerEventEntitlement(input: EventEntitlementRequest & { idToken: string }): Promise<EventEntitlementResult> {
  const normalized = normalizeEventEntitlementRequest(input);
  await assertTenantDepartmentAdmin(input.idToken, normalized.organisationId);

  const accessMode = await organisationAccessMode(normalized.organisationId);
  if (!isPerEventAccessMode(accessMode)) {
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
      ...initialEventEntitlementFields(normalized),
      createdAt: now,
      updatedAt: now,
    });
  } catch (error) {
    if (isAlreadyExists(error)) {
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

  return {
    ok: true,
    skipped: false,
    existing: false,
    entitlementId,
    organisationId: normalized.organisationId,
    eventId: normalized.eventId,
  };
}
