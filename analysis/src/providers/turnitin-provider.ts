import { defaultTurnitinCapabilitiesWhenUnknown, normalizeCapabilities } from '../capabilities.js';
import type { AnalysisCapability, TurnitinCredentials } from '../types.js';
import type {
  AnalysisProvider,
  ProviderConnectionResult,
  ProviderResultPayload,
  ProviderStatusResult,
  ProviderSubmitInput,
  ProviderSubmitResult,
} from './analysis-provider.js';

function normalizeBaseUrl(raw: string): string {
  const trimmed = raw.trim().replace(/\/+$/, '');
  if (trimmed.endsWith('/api/v1')) return trimmed;
  if (trimmed.endsWith('/api')) return `${trimmed}/v1`;
  return `${trimmed}/api/v1`;
}

function turnitinHeaders(credentials: TurnitinCredentials): Record<string, string> {
  return {
    Authorization: `Bearer ${credentials.apiKey}`,
    'X-Turnitin-Integration-Name': credentials.integrationName,
    'X-Turnitin-Integration-Version': credentials.integrationVersion,
    Accept: 'application/json',
  };
}

async function turnitinFetch(
  credentials: TurnitinCredentials,
  path: string,
  init?: RequestInit,
): Promise<Response> {
  const base = normalizeBaseUrl(credentials.apiBaseUrl);
  const url = `${base}${path.startsWith('/') ? path : `/${path}`}`;
  return fetch(url, {
    ...init,
    headers: {
      ...turnitinHeaders(credentials),
      ...(init?.headers ?? {}),
    },
  });
}

function mapTurnitinStatus(raw: unknown): 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED' {
  const text = String(raw ?? '').trim().toUpperCase();
  if (text.includes('COMPLETE') || text.includes('SUCCESS')) return 'COMPLETED';
  if (text.includes('FAIL') || text.includes('ERROR')) return 'FAILED';
  if (text.includes('PROCESS') || text.includes('UPLOAD')) return 'PROCESSING';
  return 'PROCESSING';
}

function asObject(raw: unknown): Record<string, unknown> {
  if (raw != null && typeof raw === 'object' && !Array.isArray(raw)) {
    return raw as Record<string, unknown>;
  }
  return {};
}

export class TurnitinAnalysisProvider implements AnalysisProvider {
  readonly id = 'turnitin' as const;

  async testConnection(credentials: TurnitinCredentials): Promise<ProviderConnectionResult> {
    try {
      const capabilities = await this.getCapabilities(credentials);
      return {
        ok: true,
        message: 'Turnitin Core API responded successfully.',
        capabilities,
      };
    } catch (error) {
      return {
        ok: false,
        message: error instanceof Error ? error.message : 'Turnitin connection failed.',
        capabilities: [],
      };
    }
  }

  async getCapabilities(credentials: TurnitinCredentials): Promise<AnalysisCapability[]> {
    const response = await turnitinFetch(credentials, '/features', { method: 'GET' });
    if (response.status === 401 || response.status === 403) {
      throw new Error('Turnitin rejected the API key or integration headers.');
    }
    if (response.status === 404) {
      return defaultTurnitinCapabilitiesWhenUnknown();
    }
    if (!response.ok) {
      const text = (await response.text()).trim();
      throw new Error(
        text.length > 0 ? text.slice(0, 240) : `Turnitin returned HTTP ${response.status}.`,
      );
    }
    let body: unknown = null;
    try {
      body = await response.json();
    } catch {
      return defaultTurnitinCapabilitiesWhenUnknown();
    }
    const normalized = normalizeCapabilities(body);
    return normalized.length > 0 ? normalized : defaultTurnitinCapabilitiesWhenUnknown();
  }

  async submitAnalysis(
    credentials: TurnitinCredentials,
    input: ProviderSubmitInput,
  ): Promise<ProviderSubmitResult> {
    const createResponse = await turnitinFetch(credentials, '/submissions', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: input.title,
        owner: input.analysisId,
        metadata: {
          ideaId: input.ideaId,
          hackzAnalysisId: input.analysisId,
          organisationId: input.organisationId,
        },
      }),
    });
    if (!createResponse.ok) {
      const text = (await createResponse.text()).trim();
      throw new Error(text.length > 0 ? text.slice(0, 240) : 'Turnitin submission create failed.');
    }
    const created = asObject(await createResponse.json());
    const submissionId = String(created.id ?? created.submission_id ?? '').trim();
    if (submissionId.length === 0) {
      throw new Error('Turnitin did not return a submission id.');
    }

    const textBody = (input.text ?? '').trim();
    if (textBody.length > 0) {
      const uploadResponse = await turnitinFetch(credentials, `/submissions/${submissionId}/original`, {
        method: 'PUT',
        headers: { 'Content-Type': 'text/plain' },
        body: textBody,
      });
      if (!uploadResponse.ok) {
        const text = (await uploadResponse.text()).trim();
        throw new Error(text.length > 0 ? text.slice(0, 240) : 'Turnitin text upload failed.');
      }
    }

    return {
      providerSubmissionId: submissionId,
      status: 'PROCESSING',
      mode: 'async',
    };
  }

  async getStatus(
    credentials: TurnitinCredentials,
    providerSubmissionId: string,
  ): Promise<ProviderStatusResult> {
    const response = await turnitinFetch(credentials, `/submissions/${providerSubmissionId}`, {
      method: 'GET',
    });
    if (!response.ok) {
      return {
        status: 'FAILED',
        providerSubmissionId,
        errorMessage: `Turnitin status HTTP ${response.status}`,
      };
    }
    const body = asObject(await response.json());
    const status = mapTurnitinStatus(body.status ?? body.state ?? body.processing_state);
    return { status, providerSubmissionId };
  }

  async getResult(
    credentials: TurnitinCredentials,
    providerSubmissionId: string,
  ): Promise<ProviderResultPayload> {
    const submissionResponse = await turnitinFetch(credentials, `/submissions/${providerSubmissionId}`, {
      method: 'GET',
    });
    if (!submissionResponse.ok) {
      return {
        status: 'FAILED',
        raw: { error: `Turnitin submission HTTP ${submissionResponse.status}` },
      };
    }
    const submission = asObject(await submissionResponse.json());
    let similarityRaw: Record<string, unknown> = submission;
    const similarityResponse = await turnitinFetch(
      credentials,
      `/submissions/${providerSubmissionId}/similarity`,
      { method: 'GET' },
    );
    if (similarityResponse.ok) {
      similarityRaw = { ...submission, ...asObject(await similarityResponse.json()) };
    }

    const status = mapTurnitinStatus(
      similarityRaw.status ?? submission.status ?? submission.state ?? submission.processing_state,
    );
    const similarityScore =
      similarityRaw.overall_match_percentage ??
      similarityRaw.overallMatchPercentage ??
      similarityRaw.similarity_score;

    return {
      status: status === 'FAILED' ? 'FAILED' : status === 'COMPLETED' ? 'COMPLETED' : 'PROCESSING',
      similarityScore:
        similarityScore == null ? undefined : Number(similarityScore as string | number),
      raw: similarityRaw,
    };
  }

  async getReport(
    credentials: TurnitinCredentials,
    providerSubmissionId: string,
  ): Promise<{ reportViewerUrl: string | null }> {
    const response = await turnitinFetch(
      credentials,
      `/submissions/${providerSubmissionId}/similarity/viewers`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ viewer_user_id: providerSubmissionId }),
      },
    );
    if (!response.ok) {
      return { reportViewerUrl: null };
    }
    const body = asObject(await response.json());
    const url = String(body.viewer_url ?? body.viewerUrl ?? body.url ?? '').trim();
    return { reportViewerUrl: url.length > 0 ? url : null };
  }
}

export function parseTurnitinCredentials(raw: Record<string, unknown>): TurnitinCredentials {
  const apiBaseUrl = String(raw.apiBaseUrl ?? '').trim();
  const apiKey = String(raw.apiKey ?? '').trim();
  const integrationName = String(
    raw.integrationName ?? process.env.HACKZ_INTEGRATION_NAME ?? 'Hackz',
  ).trim();
  const integrationVersion = String(
    raw.integrationVersion ?? process.env.HACKZ_INTEGRATION_VERSION ?? '1.0.2',
  ).trim();
  if (apiBaseUrl.length === 0 || apiKey.length === 0) {
    throw new Error('Turnitin requires apiBaseUrl and apiKey.');
  }
  if (integrationName.length === 0 || integrationVersion.length === 0) {
    throw new Error('Turnitin requires integration name and version headers.');
  }
  return { apiBaseUrl, apiKey, integrationName, integrationVersion };
}
