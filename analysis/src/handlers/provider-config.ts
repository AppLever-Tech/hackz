import { AnalysisError } from '../errors.js';
import { tenantApp, tenantFirestore } from '../firebase-apps.js';
import { parseTurnitinCredentials } from '../providers/turnitin-provider.js';
import { providerFor } from '../providers/registry.js';
import { readPublicProviderConfig, writePublicProviderConfig } from '../public-config.js';
import { loadProviderCredentials, storeProviderCredentials, deleteProviderCredentials } from '../secrets.js';
import { assertAuthenticatedTenantUser } from '../tenant-auth.js';
import type { AnalysisProviderId, PublicProviderConfig, TurnitinCredentials } from '../types.js';

function parseProvider(raw: unknown): AnalysisProviderId {
  const id = String(raw ?? '').trim().toLowerCase();
  if (id === 'turnitin' || id === 'drillbit') return id;
  throw new AnalysisError('INVALID_INPUT', 'provider must be turnitin or drillbit.');
}

async function credentialsForProvider(
  organisationId: string,
  provider: AnalysisProviderId,
  inline?: Record<string, unknown>,
): Promise<TurnitinCredentials> {
  if (inline != null && Object.keys(inline).length > 0) {
    if (provider !== 'turnitin') {
      throw new AnalysisError('PROVIDER_NOT_AVAILABLE', 'Only Turnitin credentials can be saved in this phase.');
    }
    return parseTurnitinCredentials(inline);
  }
  const stored = await loadProviderCredentials<TurnitinCredentials>(organisationId, provider);
  if (stored == null) {
    throw new AnalysisError('NOT_CONFIGURED', 'Provider credentials are not configured.');
  }
  return stored;
}

export async function handleSaveProviderCredentials(input: {
  organisationId: string;
  idToken: string;
  provider: unknown;
  credentials: Record<string, unknown>;
  enabled?: boolean;
}): Promise<{ ok: true; config: PublicProviderConfig }> {
  const ctx = await assertAuthenticatedTenantUser({
    organisationId: input.organisationId,
    idToken: input.idToken,
    requireCollegeAdmin: true,
    allowOrgAdminRead: false,
  });

  const provider = parseProvider(input.provider);
  if (provider === 'drillbit') {
    throw new AnalysisError(
      'PROVIDER_NOT_AVAILABLE',
      'DrillBit is not available until provider API details are confirmed.',
    );
  }

  const parsed = parseTurnitinCredentials(input.credentials);
  await storeProviderCredentials({
    organisationId: ctx.tenant.organisationId,
    provider,
    payload: parsed,
  });

  const adapter = providerFor(provider);
  const test = await adapter.testConnection(parsed);
  const db = tenantFirestore(tenantApp(ctx.tenant.tenantId, ctx.tenant.firebaseProjectId));
  const config: PublicProviderConfig = {
    organisationId: ctx.tenant.organisationId,
    provider,
    enabled: input.enabled !== false,
    connectionStatus: test.ok ? 'connected' : 'error',
    capabilities: test.capabilities,
    lastVerifiedAt: test.ok ? new Date().toISOString() : null,
    credentialsConfigured: true,
    lastError: test.ok ? null : test.message,
    apiBaseUrl: parsed.apiBaseUrl,
    integrationName: parsed.integrationName,
  };
  await writePublicProviderConfig(db, config);
  return { ok: true, config };
}

export async function handleTestConnection(input: {
  organisationId: string;
  idToken: string;
  provider: unknown;
  credentials?: Record<string, unknown>;
}): Promise<{ ok: boolean; message: string; config: PublicProviderConfig }> {
  const ctx = await assertAuthenticatedTenantUser({
    organisationId: input.organisationId,
    idToken: input.idToken,
    requireCollegeAdmin: true,
    allowOrgAdminRead: false,
  });
  const provider = parseProvider(input.provider);
  const creds = await credentialsForProvider(
    ctx.tenant.organisationId,
    provider,
    input.credentials,
  );
  const adapter = providerFor(provider);
  const test = await adapter.testConnection(creds);
  const db = tenantFirestore(tenantApp(ctx.tenant.tenantId, ctx.tenant.firebaseProjectId));
  const existing = (await readPublicProviderConfig(db, ctx.tenant.organisationId)) ?? {
    organisationId: ctx.tenant.organisationId,
    provider,
    enabled: false,
    connectionStatus: 'not_configured' as const,
    capabilities: [],
    lastVerifiedAt: null,
    credentialsConfigured: input.credentials == null,
    lastError: null,
    apiBaseUrl: creds.apiBaseUrl,
    integrationName: creds.integrationName,
  };

  const config: PublicProviderConfig = {
    ...existing,
    provider,
    connectionStatus: test.ok ? 'connected' : 'error',
    capabilities: test.capabilities,
    lastVerifiedAt: test.ok ? new Date().toISOString() : existing.lastVerifiedAt,
    lastError: test.ok ? null : test.message,
    credentialsConfigured: existing.credentialsConfigured || input.credentials != null,
    apiBaseUrl: creds.apiBaseUrl,
    integrationName: creds.integrationName,
  };
  await writePublicProviderConfig(db, config);
  return { ok: test.ok, message: test.message, config };
}

export async function handleClearCredentials(input: {
  organisationId: string;
  idToken: string;
}): Promise<{ ok: true }> {
  const ctx = await assertAuthenticatedTenantUser({
    organisationId: input.organisationId,
    idToken: input.idToken,
    requireCollegeAdmin: true,
    allowOrgAdminRead: false,
  });
  const db = tenantFirestore(tenantApp(ctx.tenant.tenantId, ctx.tenant.firebaseProjectId));
  const existing = await readPublicProviderConfig(db, ctx.tenant.organisationId);
  const provider = existing?.provider ?? 'turnitin';
  await deleteProviderCredentials(ctx.tenant.organisationId, provider);
  await writePublicProviderConfig(db, {
    organisationId: ctx.tenant.organisationId,
    provider,
    enabled: false,
    connectionStatus: 'not_configured',
    capabilities: [],
    lastVerifiedAt: null,
    credentialsConfigured: false,
    lastError: null,
    apiBaseUrl: null,
    integrationName: null,
  });
  return { ok: true };
}
