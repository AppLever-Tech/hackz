import type {
  AnalysisCapability,
  AnalysisJobStatus,
  AnalysisProviderId,
  TurnitinCredentials,
} from '../types.js';

export type ProviderConnectionResult = {
  ok: boolean;
  message: string;
  capabilities: AnalysisCapability[];
};

export type ProviderSubmitInput = {
  organisationId: string;
  ideaId: string;
  analysisId: string;
  title: string;
  text?: string;
  fileUrl?: string;
};

export type ProviderSubmitResult = {
  providerSubmissionId: string;
  status: AnalysisJobStatus;
  mode: 'sync' | 'async';
};

export type ProviderStatusResult = {
  status: AnalysisJobStatus;
  providerSubmissionId: string;
  errorMessage?: string;
};

export type ProviderResultPayload = {
  status: AnalysisJobStatus;
  similarityScore?: number;
  reportViewerUrl?: string;
  raw?: Record<string, unknown>;
};

export interface AnalysisProvider {
  readonly id: AnalysisProviderId;
  testConnection(credentials: TurnitinCredentials): Promise<ProviderConnectionResult>;
  getCapabilities(credentials: TurnitinCredentials): Promise<AnalysisCapability[]>;
  submitAnalysis(
    credentials: TurnitinCredentials,
    input: ProviderSubmitInput,
  ): Promise<ProviderSubmitResult>;
  getStatus(credentials: TurnitinCredentials, providerSubmissionId: string): Promise<ProviderStatusResult>;
  getResult(
    credentials: TurnitinCredentials,
    providerSubmissionId: string,
  ): Promise<ProviderResultPayload>;
  getReport(
    credentials: TurnitinCredentials,
    providerSubmissionId: string,
  ): Promise<{ reportViewerUrl: string | null }>;
}
