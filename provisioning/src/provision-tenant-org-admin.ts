import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneFirestore, tenantApp, tenantAuth, tenantFirestore } from './firebase-apps.js';
import {
  assertControlPlaneReachable,
  assertTenantAuthorized,
  resolveAuthUid,
} from './provision-auth.js';
import {
  isProvisioningAuthorized,
  markHackzOrgAdminConfigured,
  resolveTenantFromRegistry,
} from './tenant-registry.js';
import {
  HKZ_ORG_ADMINS,
  HKZ_USERS,
  ORG_ADMIN_ROLE,
  ORG_TYPE_COLLEGE,
  USER_STATUS_ACTIVE,
  type ProvisionTenantOrgAdminRequest,
  type ProvisionTenantOrgAdminResult,
} from './types.js';
import { isValidE164, normalizePhoneE164 } from './phone.js';

type HackzOrgAdminRecord = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  isActive: boolean;
};

function isOrgAdmin(data: DocumentData | undefined): boolean {
  if (data == null) return false;
  if (String(data.role ?? '').trim() === ORG_ADMIN_ROLE) return true;
  const roles = data.roles;
  return Array.isArray(roles) && roles.some((role) => String(role).trim() === ORG_ADMIN_ROLE);
}

async function loadHackzOrgAdmin(hackzOrgAdminId: string): Promise<HackzOrgAdminRecord> {
  const id = hackzOrgAdminId.trim();
  if (id.length === 0) {
    throw new ProvisionError('INVALID_INPUT', 'hackzOrgAdminId is required.');
  }
  const snap = await controlPlaneFirestore().collection(HKZ_ORG_ADMINS).doc(id).get();
  if (!snap.exists) {
    throw new ProvisionError('INVALID_INPUT', 'That Hackz org admin does not exist on the Control Plane.');
  }
  const data = snap.data() ?? {};
  const phone = normalizePhoneE164(String(data.phone ?? '').trim());
  if (!isValidE164(phone)) {
    throw new ProvisionError('INVALID_INPUT', 'Hackz org admin phone is invalid.');
  }
  const record: HackzOrgAdminRecord = {
    id: snap.id,
    firstName: String(data.firstName ?? '').trim(),
    lastName: String(data.lastName ?? '').trim(),
    email: String(data.email ?? '').trim().toLowerCase(),
    phone,
    isActive: data.isActive !== false,
  };
  if (record.firstName.length === 0 || record.lastName.length === 0 || record.email.length === 0) {
    throw new ProvisionError('INVALID_INPUT', 'Hackz org admin profile is incomplete.');
  }
  if (!record.isActive) {
    throw new ProvisionError('INVALID_INPUT', 'That Hackz org admin is inactive.');
  }
  return record;
}

function assertOrgAssignment(data: DocumentData, organisationId: string): void {
  const assignedOrganisationIds = data.assignedOrganisationIds;
  const orgAssigned =
    Array.isArray(assignedOrganisationIds) &&
    assignedOrganisationIds.some((value) => String(value).trim() === organisationId);
  if (!orgAssigned) {
    throw new ProvisionError(
      'INVALID_INPUT',
      'Assign this Hackz org admin to the organisation on the Control Plane first.',
    );
  }
}

function orgAdminDocument(input: {
  userId: string;
  organisationId: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
}): Record<string, unknown> {
  const now = Timestamp.now();
  return {
    userId: input.userId,
    firstName: input.firstName,
    lastName: input.lastName,
    email: input.email,
    phone: input.phone,
    role: ORG_ADMIN_ROLE,
    roles: [ORG_ADMIN_ROLE],
    orgType: ORG_TYPE_COLLEGE,
    orgId: input.organisationId,
    department: '',
    departmentCode: '',
    status: USER_STATUS_ACTIVE,
    createdAt: now,
    approvedAt: now,
  };
}

export async function provisionTenantOrgAdmin(
  request: ProvisionTenantOrgAdminRequest,
): Promise<ProvisionTenantOrgAdminResult> {
  try {
    const tenantProjectId = String(request.tenantProjectId ?? '').trim();
    if (tenantProjectId.length === 0) {
      throw new ProvisionError('INVALID_INPUT', 'tenantProjectId is required.');
    }
    const hackzOrgAdminId = String(request.hackzOrgAdminId ?? '').trim();
    const orgAdminSnap = await controlPlaneFirestore().collection(HKZ_ORG_ADMINS).doc(hackzOrgAdminId).get();
    if (!orgAdminSnap.exists) {
      throw new ProvisionError('INVALID_INPUT', 'That Hackz org admin does not exist on the Control Plane.');
    }
    const hackzOrgAdmin = await loadHackzOrgAdmin(hackzOrgAdminId);
    await assertControlPlaneReachable();
    const tenant = await resolveTenantFromRegistry({
      tenantProjectId,
      organisationId: String(request.organisationId ?? '').trim(),
    });
    assertOrgAssignment(orgAdminSnap.data() ?? {}, tenant.organisationId);
    if (tenant.provisioningAuthorization === 'revoked') {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'Provisioning access has been revoked by the organisation.',
      );
    }
    if (!isProvisioningAuthorized(tenant.provisioningAuthorization)) {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'Validate college authorization before provisioning a Hackz org admin.',
      );
    }

    const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
    await assertTenantAuthorized(app);
    const auth = tenantAuth(app);
    const db = tenantFirestore(app);

    const { uid, created } = await resolveAuthUid(auth, hackzOrgAdmin);
    const profileRef = db.collection(HKZ_USERS).doc(uid);
    const profile = await profileRef.get();
    if (profile.exists) {
      const data = profile.data() ?? {};
      const orgId = String(data.orgId ?? '').trim();
      if (orgId.length > 0 && orgId !== tenant.organisationId) {
        throw new ProvisionError(
          'AUTH_CONFLICT',
          'That phone already belongs to another organisation in this workspace.',
        );
      }
      if (!isOrgAdmin(data) && String(data.role ?? '').trim().length > 0) {
        throw new ProvisionError(
          'AUTH_CONFLICT',
          'That phone already exists as a different role in this tenant.',
        );
      }
    }

    const unchanged =
      profile.exists &&
      isOrgAdmin(profile.data()) &&
      String(profile.data()?.phone ?? '').trim() === hackzOrgAdmin.phone &&
      String(profile.data()?.orgId ?? '').trim() === tenant.organisationId &&
      String(profile.data()?.status ?? '').trim() === USER_STATUS_ACTIVE;

    const payload = orgAdminDocument({
      userId: uid,
      organisationId: tenant.organisationId,
      firstName: hackzOrgAdmin.firstName,
      lastName: hackzOrgAdmin.lastName,
      email: hackzOrgAdmin.email,
      phone: hackzOrgAdmin.phone,
    });
    if (profile.exists) {
      delete payload.createdAt;
    }
    try {
      await profileRef.set(payload, { merge: true });
    } catch (error) {
      if (created) {
        try {
          await auth.deleteUser(uid);
        } catch {
          // Best-effort compensation.
        }
      }
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'The college must authorize Hackz to write tenant Firestore.',
        );
      }
      throw new ProvisionError('WRITE_FAILED', 'Unable to create the Hackz org admin profile.');
    }

    await markHackzOrgAdminConfigured(tenant.tenantId, hackzOrgAdmin.id);

    return {
      ok: true,
      unchanged,
      tenantProjectId: tenant.firebaseProjectId,
      tenantId: tenant.tenantId,
      organisationId: tenant.organisationId,
      hackzOrgAdminId: hackzOrgAdmin.id,
      userId: uid,
      phone: hackzOrgAdmin.phone,
      email: hackzOrgAdmin.email,
    };
  } catch (error) {
    if (error instanceof ProvisionError) return error.toResult();
    return {
      ok: false,
      code: 'WRITE_FAILED',
      message: error instanceof Error ? error.message : 'Provisioning failed.',
    };
  }
}
