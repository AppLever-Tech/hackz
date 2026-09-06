import { getAuth } from 'firebase-admin/auth';
import { Timestamp } from 'firebase-admin/firestore';
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
import { normalizeProvisionRequest } from './validate.js';

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
        ? 'This college has not authorized the Hackz provisioning identity on its Firebase project.'
        : 'Unable to access tenant Firebase Auth for provisioning.',
    );
  }
}

async function existingCollegeAdmin(
  db: ReturnType<typeof tenantFirestore>,
  organisationId: string,
): Promise<string | null> {
  const snap = await db
    .collection(HKZ_USERS)
    .where('orgId', '==', organisationId)
    .limit(50)
    .get();
  const admin = snap.docs.find((doc) => {
    const data = doc.data();
    if (String(data.role ?? '').trim() === COLLEGE_ADMIN_ROLE) return true;
    const roles = data.roles;
    return Array.isArray(roles) && roles.some((role) => String(role).trim() === COLLEGE_ADMIN_ROLE);
  });
  return admin?.id ?? null;
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

    const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
    await assertTenantAuthorized(app);
    const auth = tenantAuth(app);
    const db = tenantFirestore(app);

    const existingAdmin = await existingCollegeAdmin(db, tenant.organisationId).catch((error) => {
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'This college has not authorized Hackz to read tenant Firestore.',
        );
      }
      throw error;
    });
    if (existingAdmin != null) {
      throw new ProvisionError(
        'ADMIN_EXISTS',
        'This organisation already has a College Admin.',
      );
    }

    let existingAuthUid: string | undefined;
    try {
      existingAuthUid = (await auth.getUserByPhoneNumber(input.phone)).uid;
    } catch (error) {
      const code = error != null && typeof error === 'object' && 'code' in error
        ? String(error.code)
        : '';
      if (code === 'auth/user-not-found') {
        existingAuthUid = undefined;
      } else if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'This college has not authorized Hackz to read tenant Auth users.',
        );
      } else {
        throw error;
      }
    }
    if (existingAuthUid != null) {
      throw new ProvisionError(
        'AUTH_CONFLICT',
        'That phone already exists in this tenant’s Authentication users.',
      );
    }

    const created = await auth.createUser({
      phoneNumber: input.phone,
      email: input.email,
      displayName: `${input.firstName} ${input.lastName}`.trim(),
      disabled: false,
    }).catch((error) => {
      const code = error != null && typeof error === 'object' && 'code' in error
        ? String(error.code)
        : '';
      if (code === 'auth/phone-number-already-exists' || code === 'auth/email-already-exists') {
        throw new ProvisionError(
          'AUTH_CONFLICT',
          'That phone or email already exists in this tenant’s Authentication users.',
        );
      }
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'This college has not authorized Hackz to create tenant Auth users.',
        );
      }
      throw error;
    });

    try {
      await db
        .collection(HKZ_USERS)
        .doc(created.uid)
        .create(
          collegeAdminDocument({
            userId: created.uid,
            organisationId: tenant.organisationId,
            firstName: input.firstName,
            lastName: input.lastName,
            email: input.email,
            phone: input.phone,
          }),
        );
    } catch (error) {
      try {
        await auth.deleteUser(created.uid);
      } catch {
        // Best-effort compensation so a failed profile write does not leave Auth-only state.
      }
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'This college has not authorized Hackz to write tenant Firestore.',
        );
      }
      throw new ProvisionError('WRITE_FAILED', 'Unable to create the College Admin profile.');
    }

    try {
      await markInitialAdminConfigured(tenant.tenantId);
    } catch {
      // CADM lives on the tenant. Control Plane status is metadata only.
    }

    return {
      ok: true,
      tenantProjectId: tenant.firebaseProjectId,
      tenantId: tenant.tenantId,
      organisationId: tenant.organisationId,
      userId: created.uid,
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
