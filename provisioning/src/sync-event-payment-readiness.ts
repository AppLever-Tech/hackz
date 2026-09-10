import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { eventEntitlementDocId } from './event-entitlement.js';
import { isPermissionDenied, ProvisionError } from './errors.js';
import {
  controlPlaneApp,
  controlPlaneFirestore,
  tenantApp,
  tenantAuth,
  tenantFirestore,
} from './firebase-apps.js';
import {
  alignTenantCommercialAccess,
  entitlementRef,
  loadEventPaymentReadiness,
  paymentReadinessFields,
} from './event-payment-readiness.js';
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import {
  COLLEGE_ADMIN_ROLE,
  COORDINATOR_ROLE,
  DEPARTMENT_ADMIN_ROLE,
  HKZ_USERS,
} from './types.js';

export type SyncEventPaymentReadinessResult = {
  ok: true;
  entitlementId: string;
  organisationId: string;
  eventId: string;
  paymentStatus: string;
  lumpSumVerified: boolean;
  ideaPaymentCount: number;
  ideaPaymentsVerified: number;
  ready: boolean;
};

function hasRole(data: DocumentData | undefined, role: string): boolean {
  if (data == null) return false;
  if (String(data.role ?? '').trim() === role) return true;
  const roles = data.roles;
  return Array.isArray(roles) && roles.some((value) => String(value).trim() === role);
}

async function assertSysAdminOrTenantOperator(idToken: string, organisationId: string): Promise<void> {
  if (idToken.trim().length === 0) {
    throw new ProvisionError('UNAUTHORIZED', 'Sign in to update event payment readiness.');
  }

  try {
    const decoded = await getAuth(controlPlaneApp()).verifyIdToken(idToken);
    const profile = await controlPlaneFirestore().collection(HKZ_USERS).doc(decoded.uid).get();
    const data = profile.data() ?? {};
    if (hasRole(data, 'SADM')) return;
    const phone = String(decoded.phone_number ?? '').trim();
    if (phone.length > 0) {
      const whitelist = await controlPlaneFirestore()
        .collection('hkzSysAdminWhitelist')
        .where('phone', '==', phone)
        .where('isActive', '==', true)
        .limit(1)
        .get();
      if (!whitelist.empty) return;
    }
  } catch {
    // Tenant operators use tenant Auth, not Control Plane Auth.
  }

  const tenant = await resolveActiveTenantByOrganisationId(organisationId);
  const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
  let uid = '';
  try {
    uid = (await tenantAuth(app).verifyIdToken(idToken)).uid;
  } catch {
    throw new ProvisionError('UNAUTHORIZED', 'Sign in to update event payment readiness.');
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
  const allowed =
    hasRole(data, DEPARTMENT_ADMIN_ROLE) ||
    hasRole(data, COLLEGE_ADMIN_ROLE) ||
    hasRole(data, COORDINATOR_ROLE);
  if (!profile.exists || !allowed || String(data?.orgId ?? '').trim() !== organisationId) {
    throw new ProvisionError('UNAUTHORIZED', 'Sign in to update event payment readiness.');
  }
}

export async function syncEventPaymentReadiness(input: {
  idToken: string;
  organisationId: string;
  eventId: string;
}): Promise<SyncEventPaymentReadinessResult> {
  const organisationId = input.organisationId.trim();
  const eventId = input.eventId.trim();
  if (organisationId.length === 0 || eventId.length === 0) {
    throw new ProvisionError('INVALID_INPUT', 'organisationId and eventId are required.');
  }
  await assertSysAdminOrTenantOperator(input.idToken, organisationId);

  const entitlementId = eventEntitlementDocId(organisationId, eventId);
  const ref = entitlementRef(organisationId, eventId);
  let existing;
  try {
    existing = await ref.get();
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

  const readiness = await loadEventPaymentReadiness({ organisationId, eventId });
  try {
    await ref.set(
      {
        ...paymentReadinessFields(readiness),
        updatedAt: Timestamp.now(),
      },
      { merge: true },
    );
  } catch (error) {
    throw new ProvisionError(
      'WRITE_FAILED',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot write Control Plane event entitlements.'
        : 'Unable to update event payment readiness.',
    );
  }

  if (String(existing.data()?.status ?? '') === 'pending') {
    try {
      await alignTenantCommercialAccess({
        organisationId,
        eventId,
        licensingStatus: 'pending',
      });
    } catch {
      // Payment summary is Control Plane source; tenant align is best-effort.
    }
  }

  return {
    ok: true,
    entitlementId,
    organisationId,
    eventId,
    paymentStatus: readiness.paymentStatus,
    lumpSumVerified: readiness.lumpSumVerified,
    ideaPaymentCount: readiness.ideaPaymentCount,
    ideaPaymentsVerified: readiness.ideaPaymentsVerified,
    ready: readiness.ready,
  };
}
