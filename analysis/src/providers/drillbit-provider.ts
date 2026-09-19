import { AnalysisError } from '../errors.js';
import type { AnalysisCapability, TurnitinCredentials } from '../types.js';
import type {
  AnalysisProvider,
  ProviderConnectionResult,
  ProviderResultPayload,
  ProviderStatusResult,
  ProviderSubmitInput,
  ProviderSubmitResult,
} from './analysis-provider.js';

/** Placeholder until DrillBit API documentation and credentials are available. */
export class DrillBitAnalysisProvider implements AnalysisProvider {
  readonly id = 'drillbit' as const;

  private unavailable(): never {
    throw new AnalysisError(
      'PROVIDER_NOT_AVAILABLE',
      'DrillBit integration is not available yet. Hackz will add it when provider API details are confirmed.',
    );
  }

  async testConnection(_credentials: TurnitinCredentials): Promise<ProviderConnectionResult> {
    this.unavailable();
  }

  async getCapabilities(_credentials: TurnitinCredentials): Promise<AnalysisCapability[]> {
    this.unavailable();
  }

  async submitAnalysis(
    _credentials: TurnitinCredentials,
    _input: ProviderSubmitInput,
  ): Promise<ProviderSubmitResult> {
    this.unavailable();
  }

  async getStatus(_credentials: TurnitinCredentials, _providerSubmissionId: string): Promise<ProviderStatusResult> {
    this.unavailable();
  }

  async getResult(_credentials: TurnitinCredentials, _providerSubmissionId: string): Promise<ProviderResultPayload> {
    this.unavailable();
  }

  async getReport(
    _credentials: TurnitinCredentials,
    _providerSubmissionId: string,
  ): Promise<{ reportViewerUrl: string | null }> {
    this.unavailable();
  }
}
