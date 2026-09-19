import { AnalysisError } from './errors.js';
import { tenantAuth, tenantFirestore, tenantApp } from './firebase-apps.js';
import { resolveActiveTenantByOrganisationId } from './tenant-registry.js';
import { HKZ_USERS, type ControlPlaneTenant, type TenantUserProfile } from './types.js';

export type AuthenticatedTenantContext = {
  tenant: ControlPlaneTenant;
  user: TenantUserProfile;
};

function profileFromData(uid: string, data: Record<string, unknown>): TenantUserProfile {
  const role = String(data.role ?? '').trim();
  const roles = Array.isArray(data.roles)
    ? data.roles.map((value) => String(value).trim())
    : <string[]>[];
  return {
    uid,
    orgId: String(data.orgId ?? '').trim(),
    role,
    roles,
    departmentCode: String(data.departmentCode ?? '').trim().toUpperCase(),
  };
}

async function verifyTenantSession(input: {
  organisationId: string;
  idToken: string;
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
  const user = profileFromData(uid, data);
  if (user.orgId.length === 0 || user.orgId !== tenant.organisationId) {
    throw new AnalysisError('UNAUTHORIZED', 'This account is not linked to the organisation.');
  }

  return { tenant, user };
}

function isCollegeAdmin(user: TenantUserProfile): boolean {
  return user.role === 'CADM' || user.roles.includes('CADM');
}

function isOrgAdmin(user: TenantUserProfile): boolean {
  return user.role === 'ORGADM' || user.roles.includes('ORGADM');
}

function isDepartmentAdmin(user: TenantUserProfile): boolean {
  return user.role === 'DADM' || user.roles.includes('DADM');
}

export async function assertAuthenticatedTenantUser(input: {
  organisationId: string;
  idToken: string;
  requireCollegeAdmin: boolean;
  allowOrgAdminRead: boolean;
}): Promise<AuthenticatedTenantContext> {
  const ctx = await verifyTenantSession(input);

  if (input.requireCollegeAdmin && !isCollegeAdmin(ctx.user)) {
    throw new AnalysisError('FORBIDDEN', 'Only the College Admin can change analysis provider credentials.');
  }

  if (!input.requireCollegeAdmin && input.allowOrgAdminRead) {
    if (!isCollegeAdmin(ctx.user) && !isOrgAdmin(ctx.user)) {
      throw new AnalysisError('FORBIDDEN', 'You do not have access to analysis provider settings.');
    }
  } else if (!input.requireCollegeAdmin && !isCollegeAdmin(ctx.user)) {
    throw new AnalysisError('FORBIDDEN', 'You do not have access to this operation.');
  }

  return ctx;
}

export async function assertIdeaAnalysisOperator(input: {
  organisationId: string;
  idToken: string;
}): Promise<AuthenticatedTenantContext> {
  const ctx = await verifyTenantSession(input);
  if (isCollegeAdmin(ctx.user) || isOrgAdmin(ctx.user) || isDepartmentAdmin(ctx.user)) {
    return ctx;
  }
  throw new AnalysisError('FORBIDDEN', 'Only organisation administrators can run idea analysis.');
}

export function assertDepartmentScopeForIdea(
  user: TenantUserProfile,
  idea: { teamDepartmentCode?: string; problemDepartmentCode?: string },
): void {
  if (isCollegeAdmin(user) || isOrgAdmin(user)) return;
  if (!isDepartmentAdmin(user)) return;

  const dept = user.departmentCode.trim().toUpperCase();
  if (dept.length === 0) {
    throw new AnalysisError('FORBIDDEN', 'Department administrator scope is not configured.');
  }
  const teamDept = String(idea.teamDepartmentCode ?? '').trim().toUpperCase();
  const problemDept = String(idea.problemDepartmentCode ?? '').trim().toUpperCase();
  if (dept !== teamDept && dept !== problemDept) {
    throw new AnalysisError('FORBIDDEN', 'This idea is outside your department scope.');
  }
}
