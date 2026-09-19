import type { Firestore } from 'firebase-admin/firestore';
import type {
  AnalysisCapability,
  AnalysisJobStatus,
  AnalysisProviderId,
} from './types.js';
import { HKZ_IDEA_ANALYSES } from './types.js';

export type IdeaAnalysisRecord = {
  analysisId: string;
  ideaId: string;
  organisationId: string;
  provider: AnalysisProviderId;
  status: AnalysisJobStatus;
  capabilities: AnalysisCapability[];
  similarityPercent: number | null;
  aiWritingPercent: number | null;
  matchingSourceCount: number | null;
  fullReportAvailable: boolean;
  providerSubmissionId: string | null;
  failureMessage: string | null;
  requestedByUid: string;
  createdAt: string;
  completedAt: string | null;
};

export function mapIdeaAnalysisRecord(id: string, data: Record<string, unknown>): IdeaAnalysisRecord {
  return {
    analysisId: id,
    ideaId: String(data.ideaId ?? ''),
    organisationId: String(data.organisationId ?? ''),
    provider: (String(data.provider ?? 'turnitin').trim() as AnalysisProviderId) || 'turnitin',
    status: String(data.status ?? 'PENDING').trim().toUpperCase() as AnalysisJobStatus,
    capabilities: Array.isArray(data.capabilities)
      ? data.capabilities.map((value) => String(value).trim() as AnalysisCapability)
      : [],
    similarityPercent: data.similarityPercent == null ? null : Number(data.similarityPercent),
    aiWritingPercent: data.aiWritingPercent == null ? null : Number(data.aiWritingPercent),
    matchingSourceCount: data.matchingSourceCount == null ? null : Number(data.matchingSourceCount),
    fullReportAvailable: data.fullReportAvailable === true,
    providerSubmissionId:
      data.providerSubmissionId == null ? null : String(data.providerSubmissionId),
    failureMessage: data.failureMessage == null ? null : String(data.failureMessage),
    requestedByUid: String(data.requestedByUid ?? ''),
    createdAt: String(data.createdAt ?? ''),
    completedAt: data.completedAt == null ? null : String(data.completedAt),
  };
}

export async function writeIdeaAnalysis(db: Firestore, record: IdeaAnalysisRecord): Promise<void> {
  await db
    .collection(HKZ_IDEA_ANALYSES)
    .doc(record.analysisId)
    .set(
      {
        ...record,
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
}

export async function readIdeaAnalysis(
  db: Firestore,
  analysisId: string,
): Promise<IdeaAnalysisRecord | null> {
  const snap = await db.collection(HKZ_IDEA_ANALYSES).doc(analysisId.trim()).get();
  if (!snap.exists) return null;
  return mapIdeaAnalysisRecord(snap.id, snap.data() ?? {});
}

function createdAtMillis(data: Record<string, unknown>): number {
  const raw = data.createdAt;
  if (raw == null) return 0;
  if (typeof raw === 'string') {
    const parsed = Date.parse(raw);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  if (typeof raw === 'object' && raw !== null && 'toDate' in raw) {
    const date = (raw as { toDate: () => Date }).toDate();
    return date.getTime();
  }
  return 0;
}

export async function readLatestIdeaAnalysis(
  db: Firestore,
  ideaId: string,
): Promise<IdeaAnalysisRecord | null> {
  const snap = await db.collection(HKZ_IDEA_ANALYSES).where('ideaId', '==', ideaId.trim()).get();
  if (snap.empty) return null;
  const sorted = [...snap.docs].sort(
    (a, b) => createdAtMillis(b.data()) - createdAtMillis(a.data()),
  );
  const doc = sorted[0];
  return mapIdeaAnalysisRecord(doc.id, doc.data());
}
