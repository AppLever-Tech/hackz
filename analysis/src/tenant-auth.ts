import { AnalysisError } from './errors.js';
import { tenantAuth, tenantFirestore, tenantApp } from './firebase-apps.js';
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import { HKZ_USERS, type ControlPlaneTenant, type TenantUserProfile } from './types.js';

export type AuthenticatedTenantContext = {
  tenant: ControlPlaneTenant;
  user: TenantUserProfile;
};

export async function assertAuthenticatedTenantUser(input: {
  organisationId: string;
  idToken: string;
  requireCollegeAdmin: boolean;
  allowOrgAdminRead: boolean;
}): Promise<AuthenticatedTenantContext> {
  const token = input.idToken.trim();
  if (token.length === 0) {
    throw new AnalysisError('UNAUTHORIZED', 'Sign in to continue.');
  }

  const tenant = await resolveActiveTenantByOrganisationId(input.organisationId);
  const app = tenantApp(tenant.tenantId, tenant.firebaseProjectId);

  let uid = '';
  try {
    const decoded = await tenantAuth(app).verifyIdToken(token);
    uid = decoded.uid;
  } catch {
    throw new AnalysisError('UNAUTHORIZED', 'Invalid or expired session for this organisation.');
  }

  const profileSnap = await tenantFirestore(app).collection(HKZ_USERS).doc(uid).get();
  const data = profileSnap.data() ?? {};
  const orgId = String(data.orgId ?? '').trim();
  if (orgId.length === 0 || orgId !== tenant.organisationId) {
    throw new AnalysisError('UNAUTHORIZED', 'This account is not linked to the organisation.');
  }

  const role = String(data.role ?? '').trim();
  const roles = Array.isArray(data.roles)
    ? data.roles.map((value) => String(value).trim())
    : <string[]>[];

  const isCollegeAdmin = role === 'CADM' || roles.includes('CADM');
  const isOrgAdmin = role === 'ORGADM' || roles.includes('ORGADM');

  if (input.requireCollegeAdmin && !isCollegeAdmin) {
    throw new AnalysisError('FORBIDDEN', 'Only the College Admin can change analysis provider credentials.');
  }

  if (!input.requireCollegeAdmin && input.allowOrgAdminRead) {
    if (!isCollegeAdmin && !isOrgAdmin) {
      throw new AnalysisError('FORBIDDEN', 'You do not have access to analysis provider settings.');
    }
  } else if (!input.requireCollegeAdmin && !isCollegeAdmin) {
    throw new AnalysisError('FORBIDDEN', 'You do not have access to this operation.');
  }

  return {
    tenant,
    user: { uid, orgId, role, roles },
  };
}
