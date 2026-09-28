import type { Firestore } from 'firebase-admin/firestore';
import { HKZ_ANALYSIS_CORRELATIONS, type AnalysisCorrelation, type AnalysisJobStatus, type AnalysisProviderId } from './types.js';

export async function upsertCorrelation(
  db: Firestore,
  correlation: AnalysisCorrelation,
): Promise<void> {
  const id = `${correlation.provider}_${correlation.providerSubmissionId}`;
  await db.collection(HKZ_ANALYSIS_CORRELATIONS).doc(id).set(correlation, { merge: true });
}

export async function findCorrelationByProviderSubmission(
  db: Firestore,
  provider: AnalysisProviderId,
  providerSubmissionId: string,
): Promise<AnalysisCorrelation | null> {
  const id = `${provider}_${providerSubmissionId}`;
  const snap = await db.collection(HKZ_ANALYSIS_CORRELATIONS).doc(id).get();
  if (!snap.exists) return null;
  const data = snap.data() ?? {};
  return {
    provider,
    providerSubmissionId,
    tenantProjectId: String(data.tenantProjectId ?? ''),
    organisationId: String(data.organisationId ?? ''),
    analysisId: String(data.analysisId ?? ''),
    ideaId: String(data.ideaId ?? ''),
    status: String(data.status ?? 'PENDING') as AnalysisJobStatus,
    createdAt: String(data.createdAt ?? ''),
    updatedAt: String(data.updatedAt ?? ''),
  };
}
