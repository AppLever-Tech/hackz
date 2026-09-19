import { tenantApp, tenantFirestore } from '../firebase-apps.js';
import { upsertCorrelation } from '../correlation.js';
import { loadRoutingRecord, saveRoutingRecord } from '../routing-index.js';
import type { AnalysisJobStatus } from '../types.js';

function mapWebhookStatus(raw: unknown): AnalysisJobStatus {
  const value = String(raw ?? '').trim().toUpperCase();
  if (value.includes('COMPLETE') || value.includes('SUCCESS')) return 'COMPLETED';
  if (value.includes('FAIL') || value.includes('ERROR')) return 'FAILED';
  if (value.includes('PROCESS')) return 'PROCESSING';
  return 'PROCESSING';
}

/**
 * Turnitin TCA webhook entry point (one endpoint for all tenants).
 * Correlation resolves tenant Firestore via providerSubmissionId stored at submit time.
 */
export async function handleTurnitinWebhook(body: Record<string, unknown>): Promise<{ ok: boolean }> {
  const providerSubmissionId = String(
    body.submission_id ?? body.submissionId ?? body.id ?? '',
  ).trim();
  if (providerSubmissionId.length === 0) {
    return { ok: false };
  }

  const routing = await loadRoutingRecord('turnitin', providerSubmissionId);
  if (routing == null) {
    return { ok: false };
  }

  const status = mapWebhookStatus(body.status ?? body.event ?? body.type);
  const updatedAt = new Date().toISOString();
  await saveRoutingRecord({ ...routing, status, updatedAt });

  const db = tenantFirestore(tenantApp(routing.tenantId, routing.tenantProjectId));
  await upsertCorrelation(db, {
    provider: 'turnitin',
    providerSubmissionId,
    tenantProjectId: routing.tenantProjectId,
    organisationId: routing.organisationId,
    analysisId: routing.analysisId,
    ideaId: routing.ideaId,
    status,
    createdAt: routing.updatedAt,
    updatedAt,
  });
  return { ok: true };
}
