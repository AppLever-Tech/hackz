export const HKZ_TENANTS = 'hkzTenants';
export const HKZ_USERS = 'hkzUsers';
export const HKZ_ANALYSIS_PROVIDER_CONFIG = 'hkzAnalysisProviderConfig';
export const HKZ_ANALYSIS_JOBS = 'hkzAnalysisJobs';
export const HKZ_ANALYSIS_CORRELATIONS = 'hkzAnalysisCorrelations';
export const HKZ_IDEA_ANALYSES = 'hkzIdeaAnalyses';
export const HKZ_IDEAS = 'hkzIdeas';

export type AnalysisProviderId = 'turnitin' | 'drillbit';

export type AnalysisCapability =
  | 'similarity'
  | 'aiWriting'
  | 'matchingSources'
  | 'fullReport';

export type ConnectionStatus = 'connected' | 'not_configured' | 'error';

export type AnalysisJobStatus = 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED';

export type ControlPlaneTenant = {
  tenantId: string;
  organisationId: string;
  firebaseProjectId: string;
  status: string;
};

export type TenantUserProfile = {
  uid: string;
  orgId: string;
  role: string;
  roles: string[];
  departmentCode: string;
};

export type PublicProviderConfig = {
  organisationId: string;
  provider: AnalysisProviderId;
  enabled: boolean;
  connectionStatus: ConnectionStatus;
  capabilities: AnalysisCapability[];
  lastVerifiedAt: string | null;
  credentialsConfigured: boolean;
  lastError: string | null;
  apiBaseUrl: string | null;
  integrationName: string | null;
};

export type TurnitinCredentials = {
  apiBaseUrl: string;
  apiKey: string;
  integrationName: string;
  integrationVersion: string;
};

export type AnalysisCorrelation = {
  provider: AnalysisProviderId;
  providerSubmissionId: string;
  tenantProjectId: string;
  organisationId: string;
  analysisId: string;
  ideaId: string;
  status: AnalysisJobStatus;
  createdAt: string;
  updatedAt: string;
};
