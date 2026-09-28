import type { DocumentData } from 'firebase-admin/firestore';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneFirestore, tenantApp, tenantAuth, tenantFirestore } from './firebase-apps.js';
import { assertControlPlaneReachable, assertTenantAuthorized } from './provision-auth.js';
import { isProvisioningAuthorized, resolveTenantFromRegistry } from './tenant-registry.js';
import {
  HKZ_ORG_ADMINS,
  HKZ_USERS,
  ORG_ADMIN_ROLE,
  USER_STATUS_SUSPENDED,
  type RevokeTenantOrgAdminRequest,
  type RevokeTenantOrgAdminResult,
} from './types.js';
import { normalizePhoneE164 } from './phone.js';

function isOrgAdmin(data: DocumentData | undefined): boolean {
  if (data == null) return false;
  if (String(data.role ?? '').trim() === ORG_ADMIN_ROLE) return true;
  const roles = data.roles;
  return Array.isArray(roles) && roles.some((role) => String(role).trim() === ORG_ADMIN_ROLE);
}

async function loadHackzOrgAdminPhone(hackzOrgAdminId: string): Promise<string> {
  const id = hackzOrgAdminId.trim();
  if (id.length === 0) {
    throw new ProvisionError('INVALID_INPUT', 'hackzOrgAdminId is required.');
  }
  const snap = await controlPlaneFirestore().collection(HKZ_ORG_ADMINS).doc(id).get();
  if (!snap.exists) {
    throw new ProvisionError('INVALID_INPUT', 'That Hackz org admin does not exist on the Control Plane.');
  }
  return normalizePhoneE164(String(snap.data()?.phone ?? '').trim());
}

export async function revokeTenantOrgAdmin(
  request: RevokeTenantOrgAdminRequest,
): Promise<RevokeTenantOrgAdminResult> {
  try {
    const tenantProjectId = String(request.tenantProjectId ?? '').trim();
    if (tenantProjectId.length === 0) {
      throw new ProvisionError('INVALID_INPUT', 'tenantProjectId is required.');
    }
    const phone = await loadHackzOrgAdminPhone(String(request.hackzOrgAdminId ?? ''));
    if (phone.length === 0) {
      throw new ProvisionError('INVALID_INPUT', 'Hackz org admin phone is invalid.');
    }

    await assertControlPlaneReachable();
    const tenant = await resolveTenantFromRegistry({
      tenantProjectId,
      organisationId: String(request.organisationId ?? '').trim(),
    });
    if (!isProvisioningAuthorized(tenant.provisioningAuthorization)) {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'Validate college authorization before revoking tenant org admin access.',
      );
    }

    const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
    await assertTenantAuthorized(app);
    const auth = tenantAuth(app);
    const db = tenantFirestore(app);

    const snap = await db
      .collection(HKZ_USERS)
      .where('phone', '==', phone)
      .where('orgId', '==', tenant.organisationId)
      .limit(10)
      .get()
      .catch((error) => {
        if (isPermissionDenied(error)) {
          throw new ProvisionError(
            'PROVISIONING_NOT_AUTHORIZED',
            'The college must authorize Hackz to read tenant Firestore.',
          );
        }
        throw error;
      });

    const targets = snap.docs.filter((doc) => isOrgAdmin(doc.data()));
    if (targets.length === 0) {
      return {
        ok: true,
        unchanged: true,
        tenantProjectId: tenant.firebaseProjectId,
        tenantId: tenant.tenantId,
        organisationId: tenant.organisationId,
        hackzOrgAdminId: String(request.hackzOrgAdminId ?? '').trim(),
      };
    }

    for (const doc of targets) {
      await doc.ref.set(
        {
          status: USER_STATUS_SUSPENDED,
        },
        { merge: true },
      );
    }

    try {
      const authUser = await auth.getUserByPhoneNumber(phone);
      await auth.updateUser(authUser.uid, { disabled: true });
    } catch {
      // Profile suspension is authoritative for app login; Auth disable is best-effort.
    }

    return {
      ok: true,
      unchanged: false,
      tenantProjectId: tenant.firebaseProjectId,
      tenantId: tenant.tenantId,
      organisationId: tenant.organisationId,
      hackzOrgAdminId: String(request.hackzOrgAdminId ?? '').trim(),
    };
  } catch (error) {
    if (error instanceof ProvisionError) return error.toResult();
    return {
      ok: false,
      code: 'WRITE_FAILED',
      message: error instanceof Error ? error.message : 'Revoke failed.',
    };
  }
}
