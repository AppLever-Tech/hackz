import type { AnalysisCapability } from './types.js';

const FEATURE_ALIASES: Record<string, AnalysisCapability> = {
  similarity: 'similarity',
  simcheck: 'similarity',
  sim_check: 'similarity',
  aiwriting: 'aiWriting',
  ai_writing: 'aiWriting',
  aiwritingdetection: 'aiWriting',
  ai_writing_detection: 'aiWriting',
  matchingsources: 'matchingSources',
  matching_sources: 'matchingSources',
  sourcematch: 'matchingSources',
  fullreport: 'fullReport',
  full_report: 'fullReport',
  reportviewer: 'fullReport',
};

export function normalizeCapabilities(raw: unknown): AnalysisCapability[] {
  const out = new Set<AnalysisCapability>();
  const visit = (value: unknown): void => {
    if (typeof value === 'string') {
      const key = value.trim().toLowerCase().replace(/[\s-]+/g, '_');
      const mapped = FEATURE_ALIASES[key.replace(/_/g, '')] ?? FEATURE_ALIASES[key];
      if (mapped) out.add(mapped);
      return;
    }
    if (Array.isArray(value)) {
      value.forEach(visit);
      return;
    }
    if (value != null && typeof value === 'object') {
      for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
        if (v === true || v === 'enabled') visit(k);
        else visit(v);
      }
    }
  };
  visit(raw);
  return [...out];
}

export function defaultTurnitinCapabilitiesWhenUnknown(): AnalysisCapability[] {
  return ['similarity'];
}
