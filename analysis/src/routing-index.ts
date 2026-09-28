import { controlPlaneFirestore } from './firebase-apps.js';
import type { AnalysisProviderId, AnalysisJobStatus } from './types.js';

const COLLECTION = 'hkzAnalysisRouting';

export type AnalysisRoutingRecord = {
  provider: AnalysisProviderId;
  providerSubmissionId: string;
  organisationId: string;
  tenantId: string;
  tenantProjectId: string;
  analysisId: string;
  ideaId: string;
  status: AnalysisJobStatus;
  updatedAt: string;
};

export async function saveRoutingRecord(record: AnalysisRoutingRecord): Promise<void> {
  const id = `${record.provider}_${record.providerSubmissionId}`;
  await controlPlaneFirestore().collection(COLLECTION).doc(id).set(record, { merge: true });
}

export async function loadRoutingRecord(
  provider: AnalysisProviderId,
  providerSubmissionId: string,
): Promise<AnalysisRoutingRecord | null> {
  const id = `${provider}_${providerSubmissionId}`;
  const snap = await controlPlaneFirestore().collection(COLLECTION).doc(id).get();
  if (!snap.exists) return null;
  const data = snap.data() ?? {};
  return {
    provider,
    providerSubmissionId,
    organisationId: String(data.organisationId ?? ''),
    tenantId: String(data.tenantId ?? ''),
    tenantProjectId: String(data.tenantProjectId ?? ''),
    analysisId: String(data.analysisId ?? ''),
    ideaId: String(data.ideaId ?? ''),
    status: String(data.status ?? 'PENDING') as AnalysisJobStatus,
    updatedAt: String(data.updatedAt ?? ''),
  };
}
