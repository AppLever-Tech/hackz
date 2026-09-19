import { SecretManagerServiceClient } from '@google-cloud/secret-manager';
import { AnalysisError } from './errors.js';
import { controlPlaneProjectId } from './firebase-apps.js';
import type { AnalysisProviderId, TurnitinCredentials } from './types.js';

const client = new SecretManagerServiceClient();

function secretsProjectId(): string {
  return (process.env.HACKZ_SECRETS_PROJECT_ID ?? controlPlaneProjectId()).trim();
}

function secretId(organisationId: string, provider: AnalysisProviderId): string {
  const org = organisationId.trim().replace(/[^a-zA-Z0-9_-]/g, '_');
  return `hackz-analysis-${org}-${provider}`.slice(0, 250);
}

function secretResourceName(organisationId: string, provider: AnalysisProviderId): string {
  const project = secretsProjectId();
  return `projects/${project}/secrets/${secretId(organisationId, provider)}`;
}

async function ensureSecretExists(organisationId: string, provider: AnalysisProviderId): Promise<void> {
  const parent = `projects/${secretsProjectId()}`;
  const name = secretId(organisationId, provider);
  try {
    await client.getSecret({ name: `${parent}/secrets/${name}` });
  } catch {
    await client.createSecret({
      parent,
      secretId: name,
      secret: {
        replication: { automatic: {} },
        labels: {
          hackz: 'analysis',
          organisation: organisationId.trim().slice(0, 63).replace(/[^a-zA-Z0-9_-]/g, '_'),
          provider,
        },
      },
    });
  }
}

export async function storeProviderCredentials(input: {
  organisationId: string;
  provider: AnalysisProviderId;
  payload: TurnitinCredentials | Record<string, string>;
}): Promise<void> {
  await ensureSecretExists(input.organisationId, input.provider);
  const resource = secretResourceName(input.organisationId, input.provider);
  await client.addSecretVersion({
    parent: resource,
    payload: {
      data: Buffer.from(JSON.stringify(input.payload), 'utf8'),
    },
  });
}

export async function loadProviderCredentials<T extends Record<string, string>>(
  organisationId: string,
  provider: AnalysisProviderId,
): Promise<T | null> {
  const resource = secretResourceName(organisationId, provider);
  try {
    const [version] = await client.accessSecretVersion({
      name: `${resource}/versions/latest`,
    });
    const data = version.payload?.data;
    if (data == null) return null;
    const raw = Buffer.from(data as Uint8Array).toString('utf8');
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export async function deleteProviderCredentials(
  organisationId: string,
  provider: AnalysisProviderId,
): Promise<void> {
  const resource = secretResourceName(organisationId, provider);
  try {
    await client.deleteSecret({ name: resource });
  } catch (error) {
    throw new AnalysisError(
      'SECRET_DELETE_FAILED',
      error instanceof Error ? error.message : 'Unable to delete stored credentials.',
    );
  }
}
