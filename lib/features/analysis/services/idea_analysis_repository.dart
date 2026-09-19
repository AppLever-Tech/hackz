import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../models/idea_analysis_record.dart';

class IdeaAnalysisSnapshot {
  const IdeaAnalysisSnapshot({this.latest, this.latestCompleted});

  final IdeaAnalysisRecord? latest;
  final IdeaAnalysisRecord? latestCompleted;
}

abstract final class IdeaAnalysisRepository {
  IdeaAnalysisRepository._();

  static const String collection = 'hkzIdeaAnalyses';

  static CollectionReference<Map<String, dynamic>> get _col =>
      HackzFirebase.current.firestore.collection(collection);

  static Stream<IdeaAnalysisRecord?> watchLatestForIdea(String ideaId) {
    return watchSnapshotForIdea(ideaId).map((IdeaAnalysisSnapshot snap) => snap.latest);
  }

  static Stream<IdeaAnalysisSnapshot> watchSnapshotForIdea(String ideaId) {
    final String id = ideaId.trim();
    return _col.where('ideaId', isEqualTo: id).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snap) => _buildSnapshot(snap.docs),
    );
  }

  static IdeaAnalysisSnapshot _buildSnapshot(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return const IdeaAnalysisSnapshot();
    final List<IdeaAnalysisRecord> records = docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              IdeaAnalysisRecord.fromMap(doc.id, doc.data()),
        )
        .toList(growable: false)
      ..sort((IdeaAnalysisRecord a, IdeaAnalysisRecord b) => b.createdAt.compareTo(a.createdAt));

    IdeaAnalysisRecord? latestCompleted;
    for (final IdeaAnalysisRecord record in records) {
      if (record.status == IdeaAnalysisStatus.completed) {
        latestCompleted = record;
        break;
      }
    }

    return IdeaAnalysisSnapshot(latest: records.first, latestCompleted: latestCompleted);
  }
}
