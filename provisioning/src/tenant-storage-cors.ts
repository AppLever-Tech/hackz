import { Storage } from '@google-cloud/storage';
import { isPermissionDenied, ProvisionError } from './errors.js';
import { controlPlaneFirestore } from './firebase-apps.js';

/** GCS bucket CORS rule (JSON API shape). Not exported by @google-cloud/storage types. */
export type StorageBucketCorsRule = {
  origin?: string[];
  method?: string[];
  responseHeader?: string[];
  maxAgeSeconds?: number;
};

const APPROVED_PROJECTS = 'hkzApprovedFirebaseProjects';

/** Hackz web origins that must read tenant Storage objects (certificates, attachments). */
export const HACKZ_STORAGE_CORS_ORIGINS = [
  'https://hackze.web.app',
  'https://hackze.firebaseapp.com',
  'http://localhost:8080',
  'http://localhost:5000',
  'http://127.0.0.1:8080',
];

function envOrigins(): string[] {
  const raw = (process.env.HACKZ_STORAGE_CORS_ORIGINS ?? '').trim();
  if (raw.length === 0) return HACKZ_STORAGE_CORS_ORIGINS;
  return raw
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
}

function normalizeBucketName(value: string): string {
  const trimmed = value.trim();
  if (trimmed.startsWith('gs://')) return trimmed.slice(5).trim();
  return trimmed;
}

export function mergeHackzStorageCors(
  existing: StorageBucketCorsRule[] | undefined,
  origins: string[],
): {
  cors: StorageBucketCorsRule[];
  unchanged: boolean;
} {
  const requiredOrigins = [...new Set(origins.map((o) => o.trim()).filter((o) => o.length > 0))];
  const cors = structuredClone(existing ?? []) as StorageBucketCorsRule[];

  const readRule =
    cors.find(
      (rule) =>
        rule.method?.includes('GET') &&
        !rule.method.some((m: string) => m !== 'GET' && m !== 'HEAD'),
    ) ?? null;

  if (readRule == null) {
    cors.push({
      origin: requiredOrigins,
      method: ['GET', 'HEAD'],
      responseHeader: ['Content-Type', 'Authorization', 'Content-Length', 'x-goog-resumable'],
      maxAgeSeconds: 3600,
    });
    return { cors, unchanged: false };
  }

  const current = new Set(
    (readRule.origin ?? []).map((o: string) => String(o).trim()).filter(Boolean),
  );
  let changed = false;
  for (const origin of requiredOrigins) {
    if (!current.has(origin)) {
      current.add(origin);
      changed = true;
    }
  }
  if (!changed) return { cors, unchanged: true };

  readRule.origin = [...current];
  if (!readRule.method?.includes('GET')) {
    readRule.method = [...new Set([...(readRule.method ?? []), 'GET', 'HEAD'])];
  }
  if (readRule.maxAgeSeconds == null) readRule.maxAgeSeconds = 3600;
  return { cors, unchanged: false };
}

async function resolveStorageBucket(projectId: string): Promise<string> {
  const id = projectId.trim();
  if (id.length === 0) {
    throw new ProvisionError('INVALID_INPUT', 'tenantProjectId is required.');
  }

  const db = controlPlaneFirestore();
  try {
    const doc = await db.collection(APPROVED_PROJECTS).doc(id).get();
    const fromCatalog = normalizeBucketName(String(doc.data()?.storageBucket ?? ''));
    if (fromCatalog.length > 0) return fromCatalog;
  } catch (error) {
    if (isPermissionDenied(error)) {
      throw new ProvisionError(
        'CONTROL_PLANE_UNAVAILABLE',
        'The provisioning identity cannot read approved Firebase project catalog.',
      );
    }
  }

  const storage = new Storage();
  for (const candidate of [`${id}.firebasestorage.app`, `${id}.appspot.com`]) {
    try {
      const [exists] = await storage.bucket(candidate).exists();
      if (exists) return candidate;
    } catch {
      // try next candidate
    }
  }

  throw new ProvisionError(
    'TENANT_NOT_READY',
    'No Storage bucket was found for that Firebase project. Create Storage in the tenant console first.',
  );
}

export type ConfigureTenantStorageCorsResult = {
  ok: true;
  tenantProjectId: string;
  storageBucket: string;
  unchanged: boolean;
};

export async function configureTenantStorageCors(input: {
  tenantProjectId: string;
}): Promise<ConfigureTenantStorageCorsResult> {
  const tenantProjectId = input.tenantProjectId.trim();
  const storageBucket = await resolveStorageBucket(tenantProjectId);
  const storage = new Storage();
  const bucket = storage.bucket(storageBucket);

  let metadata;
  try {
    [metadata] = await bucket.getMetadata();
  } catch (error) {
    if (isPermissionDenied(error)) {
      throw new ProvisionError(
        'PROVISIONING_NOT_AUTHORIZED',
        'Grant Storage Admin (or storage.buckets.update) on the tenant project to the Hackz provisioning service account.',
      );
    }
    throw new ProvisionError(
      'WRITE_FAILED',
      error instanceof Error ? error.message : 'Unable to read tenant Storage bucket metadata.',
    );
  }

  const { cors, unchanged } = mergeHackzStorageCors(
    metadata.cors as StorageBucketCorsRule[] | undefined,
    envOrigins(),
  );
  if (!unchanged) {
    try {
      await bucket.setMetadata({ cors });
    } catch (error) {
      if (isPermissionDenied(error)) {
        throw new ProvisionError(
          'PROVISIONING_NOT_AUTHORIZED',
          'Grant Storage Admin on the tenant project to the Hackz provisioning service account.',
        );
      }
      throw new ProvisionError(
        'WRITE_FAILED',
        error instanceof Error ? error.message : 'Unable to update tenant Storage CORS.',
      );
    }
  }

  return {
    ok: true,
    tenantProjectId,
    storageBucket,
    unchanged,
  };
}
