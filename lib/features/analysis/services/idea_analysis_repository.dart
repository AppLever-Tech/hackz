import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../models/idea_analysis_record.dart';

abstract final class IdeaAnalysisRepository {
  IdeaAnalysisRepository._();

  static const String collection = 'hkzIdeaAnalyses';

  static CollectionReference<Map<String, dynamic>> get _col =>
      HackzFirebase.current.firestore.collection(collection);

  /// Latest analysis for an idea — equality filter only (no composite Firestore index).
  static Stream<IdeaAnalysisRecord?> watchLatestForIdea(String ideaId) {
    final String id = ideaId.trim();
    return _col.where('ideaId', isEqualTo: id).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snap) => _pickLatest(snap.docs),
    );
  }

  static IdeaAnalysisRecord? _pickLatest(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return null;
    docs.sort(
      (QueryDocumentSnapshot<Map<String, dynamic>> a, QueryDocumentSnapshot<Map<String, dynamic>> b) =>
          _createdAtMillis(b.data()).compareTo(_createdAtMillis(a.data())),
    );
    final QueryDocumentSnapshot<Map<String, dynamic>> doc = docs.first;
    return IdeaAnalysisRecord.fromMap(doc.id, doc.data());
  }

  static int _createdAtMillis(Map<String, dynamic> map) {
    final Object? raw = map['createdAt'];
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is String) return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
    return 0;
  }
}
