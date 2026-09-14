export const HKZ_TENANTS = 'hkzTenants';
export const HKZ_USERS = 'hkzUsers';
/** Tenant Auth UID → `hkzUsers` profile id. Profiles are not keyed by Auth UID. */
export const HKZ_USER_AUTH_MIRROR = 'hkzUserAuthMirror';
export const HKZ_ORGANIZATIONS = 'hkzOrganizations';
export const HKZ_EVENT_ENTITLEMENTS = 'hkzEventEntitlements';
/** Tenant event documents. Hackz does not use a separate hkzEvents collection. */
export const HKZ_IDEATHONS = 'hkzIdeathons';
export const HKZ_PAYMENTS = 'hkzPayments';
export const HKZ_IDEATHON_PARTICIPATIONS = 'hkzIdeathonParticipations';
export const COLLEGE_ADMIN_ROLE = 'CADM';
export const ORG_ADMIN_ROLE = 'OADM';
export const HKZ_ORG_ADMINS = 'hkzOrgAdmins';
export const DEPARTMENT_ADMIN_ROLE = 'DADM';
export const COORDINATOR_ROLE = 'COO';
export const USER_STATUS_ACTIVE = 'active';
export const USER_STATUS_SUSPENDED = 'suspended';
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

export type ProvisionTenantOrgAdminRequest = {
  tenantProjectId: string;
  hackzOrgAdminId: string;
  organisationId?: string;
};

export type ProvisionTenantOrgAdminSuccess = {
  ok: true;
  unchanged: boolean;
  tenantProjectId: string;
  tenantId: string;
  organisationId: string;
  hackzOrgAdminId: string;
  userId: string;
  phone: string;
  email: string;
};

export type ProvisionTenantOrgAdminResult =
  | ProvisionTenantOrgAdminSuccess
  | ProvisionTenantAdminFailure;

export type RevokeTenantOrgAdminRequest = {
  tenantProjectId: string;
  hackzOrgAdminId: string;
  organisationId?: string;
};

export type RevokeTenantOrgAdminSuccess = {
  ok: true;
  unchanged: boolean;
  tenantProjectId: string;
  tenantId: string;
  organisationId: string;
  hackzOrgAdminId: string;
};

export type RevokeTenantOrgAdminResult = RevokeTenantOrgAdminSuccess | ProvisionTenantAdminFailure;

export type EventEntitlementRequest = {
  organisationId: string;
  eventId: string;
  eventName: string;
  eventType: string;
};

export type EventEntitlementSuccess = {
  ok: true;
  skipped: boolean;
  existing: boolean;
  entitlementId: string;
  organisationId: string;
  eventId: string;
};

export type EventEntitlementResult = EventEntitlementSuccess | ProvisionTenantAdminFailure;

export type SetEventEntitlementStatusRequest = {
  organisationId: string;
  eventId: string;
  status: string;
};

export type SetEventEntitlementStatusSuccess = {
  ok: true;
  unchanged: boolean;
  entitlementId: string;
  organisationId: string;
  eventId: string;
  status: 'enabled' | 'disabled';
};

export type SetEventEntitlementStatusResult =
  | SetEventEntitlementStatusSuccess
  | ProvisionTenantAdminFailure;

export type RecordEventEntitlementPaymentRequest = {
  organisationId: string;
  eventId: string;
};

export type RecordEventEntitlementPaymentSuccess = {
  ok: true;
  unchanged: boolean;
  entitlementId: string;
  organisationId: string;
  eventId: string;
  paymentStatus: 'paid';
};

export type RecordEventEntitlementPaymentResult =
  | RecordEventEntitlementPaymentSuccess
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
  hackzOrgAdminConfigured: boolean;
  hackzOrgAdminId: string;
  provisioningAuthorization: string;
};
