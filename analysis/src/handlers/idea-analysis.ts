import { randomUUID } from 'node:crypto';
import { AnalysisError } from '../errors.js';
import {
  readIdeaAnalysis,
  readLatestIdeaAnalysis,
  writeIdeaAnalysis,
  type IdeaAnalysisRecord,
} from '../idea-analysis-store.js';
import { normalizeProviderResult } from '../normalize-result.js';
import { readPublicProviderConfig } from '../public-config.js';
import { providerFor } from '../providers/registry.js';
import { saveRoutingRecord } from '../routing-index.js';
import { loadProviderCredentials } from '../secrets.js';
import {
  assertDepartmentScopeForIdea,
  assertIdeaAnalysisOperator,
  assertIdeaAnalysisReader,
} from '../tenant-auth.js';
import { tenantApp, tenantFirestore } from '../firebase-apps.js';
import type { AnalysisProviderId, TurnitinCredentials } from '../types.js';
import { HKZ_IDEAS } from '../types.js';

async function loadIdea(db: ReturnType<typeof tenantFirestore>, ideaId: string) {
  const snap = await db.collection(HKZ_IDEAS).doc(ideaId.trim()).get();
  if (!snap.exists) {
    throw new AnalysisError('NOT_FOUND', 'Idea not found.');
  }
  return { id: snap.id, ...(snap.data() ?? {}) } as Record<string, unknown> & { id: string };
}

async function providerContextForTenant(
  db: ReturnType<typeof tenantFirestore>,
  organisationId: string,
) {
  const config = await readPublicProviderConfig(db, organisationId);
  if (config == null || !config.credentialsConfigured || config.connectionStatus !== 'connected') {
    throw new AnalysisError('NOT_CONFIGURED', 'Analysis provider is not connected for this organisation.');
  }
  if (!config.enabled) {
    throw new AnalysisError('NOT_CONFIGURED', 'Analysis provider is disabled for this organisation.');
  }
  const credentials = await loadProviderCredentials<TurnitinCredentials>(organisationId, config.provider);
  if (credentials == null) {
    throw new AnalysisError('NOT_CONFIGURED', 'Provider credentials are missing.');
  }
  return { config, credentials };
}

export async function syncAnalysisFromProvider(
  record: IdeaAnalysisRecord,
  db: ReturnType<typeof tenantFirestore>,
  organisationId: string,
): Promise<IdeaAnalysisRecord> {
  if (record.status === 'COMPLETED' || record.status === 'FAILED') {
    return record;
  }
  if (record.providerSubmissionId == null || record.providerSubmissionId.trim().length === 0) {
    return record;
  }

  const { config, credentials } = await providerContextForTenant(db, organisationId);
  const adapter = providerFor(record.provider);
  const status = await adapter.getStatus(credentials, record.providerSubmissionId);
  if (status.status === 'FAILED') {
    const failed: IdeaAnalysisRecord = {
      ...record,
      status: 'FAILED',
      failureMessage: status.errorMessage ?? 'Provider analysis failed.',
      completedAt: new Date().toISOString(),
    };
    await writeIdeaAnalysis(db, failed);
    return failed;
  }
  if (status.status === 'PENDING' || status.status === 'PROCESSING') {
    const processing: IdeaAnalysisRecord = { ...record, status: status.status };
    await writeIdeaAnalysis(db, processing);
    return processing;
  }

  const result = await adapter.getResult(credentials, record.providerSubmissionId);
  const normalized = normalizeProviderResult(result, config.capabilities);
  const completed: IdeaAnalysisRecord = {
    ...record,
    status: normalized.status === 'FAILED' ? 'FAILED' : 'COMPLETED',
    similarityPercent: normalized.similarityPercent,
    aiWritingPercent: normalized.aiWritingPercent,
    matchingSourceCount: normalized.matchingSourceCount,
    fullReportAvailable: normalized.fullReportAvailable,
    failureMessage: normalized.failureMessage,
    completedAt: new Date().toISOString(),
  };
  await writeIdeaAnalysis(db, completed);
  return completed;
}

export async function handleRunIdeaAnalysis(input: {
  organisationId: string;
  idToken: string;
  ideaId: string;
}): Promise<{ ok: true; analysis: IdeaAnalysisRecord }> {
  const ctx = await assertIdeaAnalysisOperator(input);
  const db = tenantFirestore(tenantApp(ctx.tenant.tenantId, ctx.tenant.firebaseProjectId));
  const idea = await loadIdea(db, input.ideaId);
  const ideaOrg = String(idea.orgId ?? '').trim();
  if (ideaOrg !== ctx.tenant.organisationId) {
    throw new AnalysisError('FORBIDDEN', 'Idea does not belong to this organisation.');
  }
  assertDepartmentScopeForIdea(ctx.user, {
    teamDepartmentCode: String(idea.teamDepartmentCode ?? ''),
    problemDepartmentCode: String(idea.problemDepartmentCode ?? ''),
  });

  const status = String(idea.status ?? '').trim().toLowerCase();
  if (status !== 'submitted') {
    throw new AnalysisError('INVALID_INPUT', 'Analysis can only be run for submitted ideas.');
  }

  const { config, credentials } = await providerContextForTenant(db, ctx.tenant.organisationId);
  const analysisId = randomUUID();
  const now = new Date().toISOString();
  let record: IdeaAnalysisRecord = {
    analysisId,
    ideaId: input.ideaId.trim(),
    organisationId: ctx.tenant.organisationId,
    provider: config.provider,
    status: 'PENDING',
    capabilities: config.capabilities,
    similarityPercent: null,
    aiWritingPercent: null,
    matchingSourceCount: null,
    fullReportAvailable: false,
    providerSubmissionId: null,
    failureMessage: null,
    requestedByUid: ctx.user.uid,
    createdAt: now,
    completedAt: null,
  };
  await writeIdeaAnalysis(db, record);

  try {
    const adapter = providerFor(config.provider);
    const title = String(idea.ideaTitle ?? idea.title ?? 'Hackz Idea').trim() || 'Hackz Idea';
    const text = String(idea.description ?? '').trim();
    const submit = await adapter.submitAnalysis(credentials, {
      organisationId: ctx.tenant.organisationId,
      ideaId: record.ideaId,
      analysisId,
      title,
      text,
    });
    record = {
      ...record,
      status: submit.status === 'COMPLETED' ? 'COMPLETED' : 'PROCESSING',
      providerSubmissionId: submit.providerSubmissionId,
    };
    await writeIdeaAnalysis(db, record);

    await saveRoutingRecord({
      provider: config.provider,
      providerSubmissionId: submit.providerSubmissionId,
      organisationId: ctx.tenant.organisationId,
      tenantId: ctx.tenant.tenantId,
      tenantProjectId: ctx.tenant.firebaseProjectId,
      analysisId,
      ideaId: record.ideaId,
      status: record.status,
      updatedAt: new Date().toISOString(),
    });

    if (submit.mode === 'sync' && submit.status === 'COMPLETED') {
      record = await syncAnalysisFromProvider(record, db, ctx.tenant.organisationId);
    }
  } catch (error) {
    record = {
      ...record,
      status: 'FAILED',
      failureMessage: error instanceof Error ? error.message : 'Unable to start analysis.',
      completedAt: new Date().toISOString(),
    };
    await writeIdeaAnalysis(db, record);
    throw new AnalysisError('PROVIDER_ERROR', record.failureMessage ?? 'Unable to start analysis.');
  }

  return { ok: true, analysis: record };
}

export async function handleRefreshIdeaAnalysis(input: {
  organisationId: string;
  idToken: string;
  analysisId: string;
}): Promise<{ ok: true; analysis: IdeaAnalysisRecord }> {
  const ctx = await assertIdeaAnalysisOperator(input);
  const db = tenantFirestore(tenantApp(ctx.tenant.tenantId, ctx.tenant.firebaseProjectId));
  const existing = await readIdeaAnalysis(db, input.analysisId);
  if (existing == null || existing.organisationId !== ctx.tenant.organisationId) {
    throw new AnalysisError('NOT_FOUND', 'Analysis record not found.');
  }
  const idea = await loadIdea(db, existing.ideaId);
  assertDepartmentScopeForIdea(ctx.user, {
    teamDepartmentCode: String(idea.teamDepartmentCode ?? ''),
    problemDepartmentCode: String(idea.problemDepartmentCode ?? ''),
  });
  const analysis = await syncAnalysisFromProvider(existing, db, ctx.tenant.organisationId);
  return { ok: true, analysis };
}

export async function handleGetIdeaAnalysisReport(input: {
  organisationId: string;
  idToken: string;
  analysisId: string;
}): Promise<{ ok: true; reportViewerUrl: string }> {
  const ctx = await assertIdeaAnalysisReader(input);
  const db = tenantFirestore(tenantApp(ctx.tenant.tenantId, ctx.tenant.firebaseProjectId));
  const record = await readIdeaAnalysis(db, input.analysisId);
  if (record == null || record.organisationId !== ctx.tenant.organisationId) {
    throw new AnalysisError('NOT_FOUND', 'Analysis record not found.');
  }
  if (!record.fullReportAvailable || record.providerSubmissionId == null) {
    throw new AnalysisError('NOT_AVAILABLE', 'Full report is not available for this analysis.');
  }
  const idea = await loadIdea(db, record.ideaId);
  assertDepartmentScopeForIdea(ctx.user, {
    teamDepartmentCode: String(idea.teamDepartmentCode ?? ''),
    problemDepartmentCode: String(idea.problemDepartmentCode ?? ''),
  });
  const { credentials } = await providerContextForTenant(db, ctx.tenant.organisationId);
  const adapter = providerFor(record.provider);
  const report = await adapter.getReport(credentials, record.providerSubmissionId);
  if (report.reportViewerUrl == null || report.reportViewerUrl.trim().length === 0) {
    throw new AnalysisError('NOT_AVAILABLE', 'Provider did not return a report viewer URL.');
  }
  return { ok: true, reportViewerUrl: report.reportViewerUrl.trim() };
}

export async function handleGetLatestIdeaAnalysis(input: {
  organisationId: string;
  idToken: string;
  ideaId: string;
}): Promise<{ ok: true; analysis: IdeaAnalysisRecord | null }> {
  const ctx = await assertIdeaAnalysisOperator(input);
  const db = tenantFirestore(tenantApp(ctx.tenant.tenantId, ctx.tenant.firebaseProjectId));
  const latest = await readLatestIdeaAnalysis(db, input.ideaId);
  if (latest == null) {
    return { ok: true, analysis: null };
  }
  const idea = await loadIdea(db, latest.ideaId);
  assertDepartmentScopeForIdea(ctx.user, {
    teamDepartmentCode: String(idea.teamDepartmentCode ?? ''),
    problemDepartmentCode: String(idea.problemDepartmentCode ?? ''),
  });
  if (latest.status === 'PENDING' || latest.status === 'PROCESSING') {
    const refreshed = await syncAnalysisFromProvider(latest, db, ctx.tenant.organisationId);
    return { ok: true, analysis: refreshed };
  }
  return { ok: true, analysis: latest };
}
