import { getAuth } from 'firebase-admin/auth';
import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneApp, tenantApp, tenantAuth, tenantFirestore } from './firebase-apps.js';
import {
  markInitialAdminConfigured,
  resolveTenantFromRegistry,
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

function authErrorCode(error: unknown): string {
  if (error != null && typeof error === 'object' && 'code' in error) {
    return String(error.code);
  }
  return '';
}

async function assertControlPlaneReachable(): Promise<void> {
  try {
    await getAuth(controlPlaneApp()).listUsers(1);
  } catch (error) {
    throw new ProvisionError(
      'CONTROL_PLANE_UNAVAILABLE',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot access the Control Plane Firebase project.'
        : 'Unable to validate the Control Plane operation.',
    );
  }
}

async function assertTenantAuthorized(app: ReturnType<typeof tenantApp>): Promise<void> {
  try {
    await tenantAuth(app).listUsers(1);
  } catch (error) {
    throw new ProvisionError(
      'PROVISIONING_NOT_AUTHORIZED',
      isPermissionDenied(error)
        ? 'The college must authorize the Hackz provisioning identity, then Validate authorization.'
        : 'Unable to access tenant Firebase Auth for provisioning.',
    );
  }
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

async function resolveAuthUid(
  auth: ReturnType<typeof tenantAuth>,
  input: NormalizedAdminInput,
): Promise<{ uid: string; created: boolean }> {
  try {
    const existing = await auth.getUserByPhoneNumber(input.phone);
    await auth.updateUser(existing.uid, {
      email: input.email,
      displayName: `${input.firstName} ${input.lastName}`.trim(),
      disabled: false,
    });
    return { uid: existing.uid, created: false };
  } catch (error) {
    if (authErrorCode(error) !== 'auth/user-not-found') {
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'The college must authorize Hackz to read tenant Auth users.',
        );
      }
      throw error;
    }
  }

  try {
    const created = await auth.createUser({
      phoneNumber: input.phone,
      email: input.email,
      displayName: `${input.firstName} ${input.lastName}`.trim(),
      disabled: false,
    });
    return { uid: created.uid, created: true };
  } catch (error) {
    const code = authErrorCode(error);
    if (code === 'auth/phone-number-already-exists') {
      const existing = await auth.getUserByPhoneNumber(input.phone);
      return { uid: existing.uid, created: false };
    }
    if (code === 'auth/email-already-exists') {
      throw new ProvisionError(
        'AUTH_CONFLICT',
        'That email already exists in this tenant’s Authentication users.',
      );
    }
    if (isPermissionDenied(error)) {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'The college must authorize Hackz to create tenant Auth users.',
      );
    }
    throw error;
  }
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
        'The college revoked Hackz provisioning access on this Firebase project.',
      );
    }
    if (tenant.provisioningAuthorization !== 'verified') {
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

    await markInitialAdminConfigured(tenant.tenantId);

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
