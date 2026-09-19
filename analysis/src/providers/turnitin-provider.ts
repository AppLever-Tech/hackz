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
    _credentials: TurnitinCredentials,
    input: ProviderSubmitInput,
  ): Promise<ProviderSubmitResult> {
    return {
      providerSubmissionId: `pending-${input.analysisId}`,
      status: 'PENDING',
      mode: 'async',
    };
  }

  async getStatus(
    _credentials: TurnitinCredentials,
    providerSubmissionId: string,
  ): Promise<ProviderStatusResult> {
    return {
      status: 'PENDING',
      providerSubmissionId,
    };
  }

  async getResult(
    _credentials: TurnitinCredentials,
    providerSubmissionId: string,
  ): Promise<ProviderResultPayload> {
    return {
      status: 'PENDING',
      raw: { providerSubmissionId },
    };
  }

  async getReport(
    _credentials: TurnitinCredentials,
    _providerSubmissionId: string,
  ): Promise<{ reportViewerUrl: string | null }> {
    return { reportViewerUrl: null };
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
