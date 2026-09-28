import type { DocumentData } from 'firebase-admin/firestore';
import { AnalysisError, isPermissionDenied } from './errors.js';
import { controlPlaneFirestore } from './firebase-apps.js';
import { HKZ_TENANTS, type ControlPlaneTenant } from './types.js';

function asTenant(id: string, data: DocumentData): ControlPlaneTenant {
  return {
    tenantId: String(data.tenantId ?? id).trim() || id,
    organisationId: String(data.organisationId ?? '').trim(),
    firebaseProjectId: String(data.firebaseProjectId ?? '').trim(),
    status: String(data.status ?? '').trim().toLowerCase(),
  };
}

export async function resolveActiveTenantByOrganisationId(
  organisationId: string,
): Promise<ControlPlaneTenant> {
  const id = organisationId.trim();
  if (id.length === 0) {
    throw new AnalysisError('INVALID_INPUT', 'organisationId is required.');
  }

  const db = controlPlaneFirestore();
  let snap;
  try {
    snap = await db.collection(HKZ_TENANTS).where('organisationId', '==', id).get();
  } catch (error) {
    throw new AnalysisError(
      'CONTROL_PLANE_UNAVAILABLE',
      isPermissionDenied(error)
        ? 'The analysis service cannot read the Control Plane tenant registry.'
        : 'Unable to read the Control Plane tenant registry.',
    );
  }

  const matches = snap.docs
    .map((doc) => asTenant(doc.id, doc.data()))
    .filter((tenant) => tenant.status === 'active' || tenant.status === 'setup')
    .filter((tenant) => tenant.firebaseProjectId.length > 0 && tenant.organisationId.length > 0);

  if (matches.length === 0) {
    throw new AnalysisError('TENANT_NOT_FOUND', 'No active tenant is registered for that organisation.');
  }
  if (matches.length > 1) {
    throw new AnalysisError('TENANT_AMBIGUOUS', 'Multiple tenants match that organisation.');
  }
  return matches[0];
}
