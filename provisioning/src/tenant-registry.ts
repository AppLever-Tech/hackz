import { Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneFirestore } from './firebase-apps.js';
import {
  HKZ_TENANTS,
  type ControlPlaneTenant,
} from './types.js';

function asTenant(id: string, data: DocumentData): ControlPlaneTenant {
  return {
    tenantId: String(data.tenantId ?? id).trim() || id,
    organisationCode: String(data.organisationCode ?? '').trim(),
    organisationName: String(data.organisationName ?? '').trim(),
    firebaseProjectId: String(data.firebaseProjectId ?? '').trim(),
    organisationId: String(data.organisationId ?? '').trim(),
    status: String(data.status ?? '').trim().toLowerCase(),
    firebaseValidated: data.firebaseValidated === true,
    initialAdminConfigured: data.initialAdminConfigured === true,
    provisioningAuthorization: String(data.provisioningAuthorization ?? '').trim().toLowerCase(),
  };
}

export async function resolveTenantFromRegistry(input: {
  tenantProjectId: string;
  organisationId: string;
}): Promise<ControlPlaneTenant> {
  const db = controlPlaneFirestore();
  let snap;
  try {
    snap = await db
      .collection(HKZ_TENANTS)
      .where('firebaseProjectId', '==', input.tenantProjectId)
      .get();
  } catch (error) {
    throw new ProvisionError(
      'CONTROL_PLANE_UNAVAILABLE',
      isPermissionDenied(error)
        ? 'The provisioning identity cannot read the Control Plane tenant registry.'
        : 'Unable to read the Control Plane tenant registry.',
    );
  }

  const matches = snap.docs
    .map((doc) => asTenant(doc.id, doc.data()))
    .filter((tenant) => tenant.status !== 'inactive')
    .filter((tenant) =>
      input.organisationId.length === 0
        ? true
        : tenant.organisationId === input.organisationId,
    );

  if (matches.length === 0) {
    throw new ProvisionError(
      'TENANT_NOT_FOUND',
      'No Control Plane tenant is registered for that Firebase project.',
    );
  }
  if (matches.length > 1) {
    throw new ProvisionError(
      'TENANT_AMBIGUOUS',
      'Multiple organisations share that Firebase project. Pass organisationId.',
    );
  }

  const tenant = matches[0];
  if (tenant.status !== 'setup' && tenant.status !== 'active') {
    throw new ProvisionError('TENANT_NOT_READY', 'That organisation is not ready for provisioning.');
  }
  if (!tenant.firebaseValidated) {
    throw new ProvisionError(
      'TENANT_NOT_READY',
      'Finish workspace validation before provisioning the College Admin.',
    );
  }
  if (tenant.organisationId.length === 0) {
    throw new ProvisionError(
      'TENANT_NOT_READY',
      'The tenant registry has no organisation id for this workspace.',
    );
  }
  return tenant;
}

export function isProvisioningAuthorized(status: string): boolean {
  return status === 'verified' || status === 'authorized';
}

export async function markInitialAdminConfigured(tenantId: string): Promise<void> {
  await controlPlaneFirestore()
    .collection(HKZ_TENANTS)
    .doc(tenantId)
    .set(
      {
        initialAdminConfigured: true,
      },
      { merge: true },
    );
}

export async function markProvisioningAuthorization(
  tenantId: string,
  status: 'required' | 'pending' | 'verified' | 'revoked',
): Promise<void> {
  await controlPlaneFirestore()
    .collection(HKZ_TENANTS)
    .doc(tenantId)
    .set(
      {
        provisioningAuthorization: status,
        provisioningAuthorizationValidatedAt: Timestamp.now(),
      },
      { merge: true },
    );
}
