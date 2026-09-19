import type { AnalysisProviderId } from '../types.js';
import type { AnalysisProvider } from './analysis-provider.js';
import { DrillBitAnalysisProvider } from './drillbit-provider.js';
import { TurnitinAnalysisProvider } from './turnitin-provider.js';

const turnitin = new TurnitinAnalysisProvider();
const drillbit = new DrillBitAnalysisProvider();

export function providerFor(id: AnalysisProviderId): AnalysisProvider {
  switch (id) {
    case 'turnitin':
      return turnitin;
    case 'drillbit':
      return drillbit;
    default:
      throw new Error(`Unknown analysis provider: ${id as string}`);
  }
}

export function supportedProviderIds(): AnalysisProviderId[] {
  return ['turnitin', 'drillbit'];
}
