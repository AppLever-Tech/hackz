import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { tenantApp, tenantAuth, tenantFirestore } from './firebase-apps.js';
import {
  assertControlPlaneReachable,
  assertTenantAuthorized,
  resolveAuthUid,
} from './provision-auth.js';
import {
  markInitialAdminConfigured,
  resolveTenantFromRegistry,
  isProvisioningAuthorized,
} from './tenant-registry.js';
import {
  COLLEGE_ADMIN_ROLE,
  HKZ_USERS,
  ORG_TYPE_COLLEGE,
  USER_STATUS_ACTIVE,
  type ProvisionTenantAdminRequest,
  type ProvisionTenantAdminResult,
} from './types.js';
import { normalizeProvisionRequest, type NormalizedAdminInput } from './validate.js';

function isCollegeAdmin(data: DocumentData | undefined): boolean {
  if (data == null) return false;
  if (String(data.role ?? '').trim() === COLLEGE_ADMIN_ROLE) return true;
  const roles = data.roles;
  return Array.isArray(roles) && roles.some((role) => String(role).trim() === COLLEGE_ADMIN_ROLE);
}

function collegeAdminDocument(input: {
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
    role: COLLEGE_ADMIN_ROLE,
    roles: [COLLEGE_ADMIN_ROLE],
    orgType: ORG_TYPE_COLLEGE,
    orgId: input.organisationId,
    department: '',
    departmentCode: '',
    status: USER_STATUS_ACTIVE,
    createdAt: now,
    approvedAt: now,
  };
}

async function findCollegeAdmin(
  db: ReturnType<typeof tenantFirestore>,
  organisationId: string,
): Promise<{ id: string; phone: string } | null> {
  const snap = await db
    .collection(HKZ_USERS)
    .where('orgId', '==', organisationId)
    .limit(50)
    .get();
  const admin = snap.docs.find((doc) => isCollegeAdmin(doc.data()));
  if (admin == null) return null;
  return { id: admin.id, phone: String(admin.data().phone ?? '').trim() };
}

export async function provisionTenantAdmin(
  request: ProvisionTenantAdminRequest,
): Promise<ProvisionTenantAdminResult> {
  try {
    const input = normalizeProvisionRequest(request);
    await assertControlPlaneReachable();
    const tenant = await resolveTenantFromRegistry({
      tenantProjectId: input.tenantProjectId,
      organisationId: input.organisationId,
    });
    if (tenant.provisioningAuthorization === 'revoked') {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'Provisioning access has been revoked by the organisation. Re-authorization is required for future privileged provisioning.',
      );
    }
    if (!isProvisioningAuthorized(tenant.provisioningAuthorization)) {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'Validate college authorization before creating the College Admin.',
      );
    }

    const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
    await assertTenantAuthorized(app);
    const auth = tenantAuth(app);
    const db = tenantFirestore(app);

    const existingAdmin = await findCollegeAdmin(db, tenant.organisationId).catch((error) => {
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'The college must authorize Hackz to read tenant Firestore.',
        );
      }
      throw error;
    });
    if (existingAdmin != null && existingAdmin.phone !== input.phone) {
      throw new ProvisionError(
        'ADMIN_EXISTS',
        'This organisation already has a College Admin.',
      );
    }

    const { uid, created } = await resolveAuthUid(auth, input);
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
      if (!isCollegeAdmin(data) && String(data.role ?? '').trim().length > 0) {
        throw new ProvisionError(
          'AUTH_CONFLICT',
          'That phone already exists as a different role in this tenant.',
        );
      }
    }

    const payload = collegeAdminDocument({
      userId: uid,
      organisationId: tenant.organisationId,
      firstName: input.firstName,
      lastName: input.lastName,
      email: input.email,
      phone: input.phone,
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
          // Best-effort compensation only when this request created Auth.
        }
      }
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'The college must authorize Hackz to write tenant Firestore.',
        );
      }
      throw new ProvisionError('WRITE_FAILED', 'Unable to create the College Admin profile.');
    }

    await markInitialAdminConfigured(tenant.tenantId, {
      userId: uid,
      firstName: input.firstName,
      lastName: input.lastName,
      phone: input.phone,
      email: input.email,
    });

    return {
      ok: true,
      tenantProjectId: tenant.firebaseProjectId,
      tenantId: tenant.tenantId,
      organisationId: tenant.organisationId,
      userId: uid,
      phone: input.phone,
      email: input.email,
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
