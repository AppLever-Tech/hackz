import { isPermissionDenied, ProvisionError } from './errors.js';
import { tenantApp, tenantAuth, tenantFirestore } from './firebase-apps.js';
import {
  markProvisioningAuthorization,
  resolveTenantFromRegistry,
} from './tenant-registry.js';
import { HKZ_USERS, type ProvisionTenantAdminResult } from './types.js';

export type ValidateAuthorizationRequest = {
  tenantProjectId: string;
  organisationId?: string;
};

export type ValidateAuthorizationSuccess = {
  ok: true;
  tenantProjectId: string;
  tenantId: string;
  organisationId: string;
  projectReachable: true;
  authOk: true;
  firestoreOk: true;
  authorization: 'verified';
};

async function pingAuth(app: ReturnType<typeof tenantApp>): Promise<void> {
  await tenantAuth(app).listUsers(1);
}

async function pingFirestore(app: ReturnType<typeof tenantApp>): Promise<void> {
  await tenantFirestore(app).collection(HKZ_USERS).limit(1).get();
}

export async function validateProvisioningAuthorization(
  request: ValidateAuthorizationRequest,
): Promise<ProvisionTenantAdminResult | ValidateAuthorizationSuccess> {
  try {
    const tenantProjectId = request.tenantProjectId.trim();
    if (tenantProjectId.length === 0) {
      throw new ProvisionError('INVALID_INPUT', 'tenantProjectId is required.');
    }
    const tenant = await resolveTenantFromRegistry({
      tenantProjectId,
      organisationId: (request.organisationId ?? '').trim(),
    });
    const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);
    try {
      await pingAuth(app);
    } catch (error) {
      await markProvisioningAuthorization(tenant.tenantId, 'revoked').catch(() => undefined);
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        isPermissionDenied(error)
          ? 'This college has not authorized the Hackz provisioning identity for Authentication.'
          : 'Tenant Firebase Authentication is not reachable for the provisioning identity.',
      );
    }
    try {
      await pingFirestore(app);
    } catch (error) {
      await markProvisioningAuthorization(tenant.tenantId, 'revoked').catch(() => undefined);
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        isPermissionDenied(error)
          ? 'This college has not authorized the Hackz provisioning identity for Firestore.'
          : 'Tenant Firestore is not reachable for the provisioning identity.',
      );
    }
    await markProvisioningAuthorization(tenant.tenantId, 'verified');
    return {
      ok: true,
      tenantProjectId: tenant.firebaseProjectId,
      tenantId: tenant.tenantId,
      organisationId: tenant.organisationId,
      projectReachable: true,
      authOk: true,
      firestoreOk: true,
      authorization: 'verified',
    };
  } catch (error) {
    if (error instanceof ProvisionError) return error.toResult();
    return {
      ok: false,
      code: 'WRITE_FAILED',
      message: error instanceof Error ? error.message : 'Authorization validation failed.',
    };
  }
}
