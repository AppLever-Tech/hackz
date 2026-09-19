import type { Firestore, Timestamp } from 'firebase-admin/firestore';
import type {
  AnalysisCapability,
  AnalysisProviderId,
  ConnectionStatus,
  PublicProviderConfig,
} from './types.js';
import { HKZ_ANALYSIS_PROVIDER_CONFIG } from './types.js';

export async function readPublicProviderConfig(
  db: Firestore,
  organisationId: string,
): Promise<PublicProviderConfig | null> {
  const snap = await db.collection(HKZ_ANALYSIS_PROVIDER_CONFIG).doc(organisationId).get();
  if (!snap.exists) return null;
  return mapPublicConfig(organisationId, snap.data() ?? {});
}

export async function writePublicProviderConfig(
  db: Firestore,
  config: PublicProviderConfig,
): Promise<void> {
  await db
    .collection(HKZ_ANALYSIS_PROVIDER_CONFIG)
    .doc(config.organisationId)
    .set(
      {
        organisationId: config.organisationId,
        provider: config.provider,
        enabled: config.enabled,
        connectionStatus: config.connectionStatus,
        capabilities: config.capabilities,
        lastVerifiedAt: config.lastVerifiedAt,
        credentialsConfigured: config.credentialsConfigured,
        lastError: config.lastError,
        apiBaseUrl: config.apiBaseUrl,
        integrationName: config.integrationName,
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
}

function mapPublicConfig(organisationId: string, data: Record<string, unknown>): PublicProviderConfig {
  const lastVerifiedRaw = data.lastVerifiedAt;
  let lastVerifiedAt: string | null = null;
  if (typeof lastVerifiedRaw === 'string') lastVerifiedAt = lastVerifiedRaw;
  else if (lastVerifiedRaw != null && typeof lastVerifiedRaw === 'object' && 'toDate' in lastVerifiedRaw) {
    lastVerifiedAt = (lastVerifiedRaw as Timestamp).toDate().toISOString();
  }

  return {
    organisationId,
    provider: (String(data.provider ?? 'turnitin').trim() as AnalysisProviderId) || 'turnitin',
    enabled: data.enabled === true,
    connectionStatus: (String(data.connectionStatus ?? 'not_configured').trim() as ConnectionStatus),
    capabilities: Array.isArray(data.capabilities)
      ? data.capabilities.map((value) => String(value).trim() as AnalysisCapability)
      : [],
    lastVerifiedAt,
    credentialsConfigured: data.credentialsConfigured === true,
    lastError: data.lastError == null ? null : String(data.lastError),
    apiBaseUrl: data.apiBaseUrl == null ? null : String(data.apiBaseUrl),
    integrationName: data.integrationName == null ? null : String(data.integrationName),
  };
}
