import { getAuth } from 'firebase-admin/auth';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneApp, tenantApp, tenantAuth } from './firebase-apps.js';
import type { NormalizedAdminInput } from './validate.js';

export function authErrorCode(error: unknown): string {
  if (error != null && typeof error === 'object' && 'code' in error) {
    return String(error.code);
  }
  return '';
}

export async function assertControlPlaneReachable(): Promise<void> {
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

export async function assertTenantAuthorized(app: ReturnType<typeof tenantApp>): Promise<void> {
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

export async function resolveAuthUid(
  auth: ReturnType<typeof tenantAuth>,
  input: Pick<NormalizedAdminInput, 'phone' | 'email' | 'firstName' | 'lastName'>,
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
      await auth.updateUser(existing.uid, { disabled: false });
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
