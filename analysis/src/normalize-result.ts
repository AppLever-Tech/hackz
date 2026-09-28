import type { ProviderResultPayload } from './providers/analysis-provider.js';
import type { AnalysisCapability, AnalysisJobStatus } from './types.js';

export type NormalizedIdeaMetrics = {
  status: AnalysisJobStatus;
  similarityPercent: number | null;
  aiWritingPercent: number | null;
  matchingSourceCount: number | null;
  fullReportAvailable: boolean;
  failureMessage: string | null;
};

function readNumber(raw: unknown): number | null {
  if (typeof raw === 'number' && Number.isFinite(raw)) return raw;
  if (typeof raw === 'string' && raw.trim().length > 0) {
    const parsed = Number(raw);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function readCount(raw: unknown): number | null {
  const value = readNumber(raw);
  if (value == null) return null;
  return Math.max(0, Math.round(value));
}

export function normalizeProviderResult(
  payload: ProviderResultPayload,
  capabilities: AnalysisCapability[],
): NormalizedIdeaMetrics {
  const raw = payload.raw ?? {};
  const capSet = new Set(capabilities);
  const similarityPercent =
    capSet.has('similarity') && payload.similarityScore != null
      ? readNumber(payload.similarityScore)
      : capSet.has('similarity')
        ? readNumber(raw.overall_match_percentage ?? raw.similarity_percent ?? raw.similarityScore)
        : null;
  const aiWritingPercent = capSet.has('aiWriting')
    ? readNumber(raw.ai_writing_score ?? raw.aiWritingScore ?? raw.aiwriting_score)
    : null;
  const matchingSourceCount = capSet.has('matchingSources')
    ? readCount(raw.matching_sources ?? raw.matchingSources ?? raw.source_count)
    : null;
  const fullReportAvailable =
    capSet.has('fullReport') &&
    (payload.reportViewerUrl != null || raw.report_available === true || payload.status === 'COMPLETED');

  return {
    status: payload.status,
    similarityPercent,
    aiWritingPercent,
    matchingSourceCount,
    fullReportAvailable,
    failureMessage: payload.status === 'FAILED' ? String(raw.error ?? raw.message ?? 'Analysis failed.') : null,
  };
}
