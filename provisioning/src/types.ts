export const HKZ_TENANTS = 'hkzTenants';
export const HKZ_USERS = 'hkzUsers';
export const COLLEGE_ADMIN_ROLE = 'CADM';
export const USER_STATUS_ACTIVE = 'active';
export const ORG_TYPE_COLLEGE = 1;

export type ProvisionTenantAdminRequest = {
  tenantProjectId: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  /** Required when several Control Plane tenants share one Firebase project. */
  organisationId?: string;
};

export type ProvisionTenantAdminSuccess = {
  ok: true;
  tenantProjectId: string;
  tenantId: string;
  organisationId: string;
  userId: string;
  phone: string;
  email: string;
};

export type ProvisionFailureCode =
  | 'INVALID_INPUT'
  | 'CONTROL_PLANE_UNAVAILABLE'
  | 'TENANT_NOT_FOUND'
  | 'TENANT_AMBIGUOUS'
  | 'TENANT_NOT_READY'
  | 'PROVISIONING_NOT_AUTHORIZED'
  | 'ADMIN_EXISTS'
  | 'AUTH_CONFLICT'
  | 'UNAUTHORIZED'
  | 'WRITE_FAILED';

export type ProvisionTenantAdminFailure = {
  ok: false;
  code: ProvisionFailureCode;
  message: string;
};

export type ProvisionTenantAdminResult =
  | ProvisionTenantAdminSuccess
  | ProvisionTenantAdminFailure;

export type ControlPlaneTenant = {
  tenantId: string;
  organisationCode: string;
  organisationName: string;
  firebaseProjectId: string;
  organisationId: string;
  status: string;
  firebaseValidated: boolean;
  initialAdminConfigured: boolean;
  provisioningAuthorization: string;
};
