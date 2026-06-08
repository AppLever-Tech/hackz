import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/services/idea_status_helpers.dart';

/// Department-admin shortlisting workflow for evaluated ideas.
abstract final class IdeaShortlistingService {
  IdeaShortlistingService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> shortlistIdea(String ideaId) async {
    await _updateStatus(ideaId, IdeaStatus.shortlisted);
  }

  static Future<void> rejectIdea(String ideaId) async {
    await _updateStatus(ideaId, IdeaStatus.rejected);
  }

  static Future<void> shortlistMany(Iterable<String> ideaIds) async {
    await _updateMany(ideaIds, IdeaStatus.shortlisted);
  }

  static Future<void> rejectMany(Iterable<String> ideaIds) async {
    await _updateMany(ideaIds, IdeaStatus.rejected);
  }

  static Future<void> _updateMany(Iterable<String> ideaIds, IdeaStatus nextStatus) async {
    final WriteBatch batch = _db.batch();
    var count = 0;
    for (final String raw in ideaIds) {
      final String id = raw.trim();
      if (id.isEmpty) continue;
      batch.update(_db.collection(FirestoreUtils.hkzIdeas).doc(id), <String, dynamic>{
        'status': nextStatus.value,
      });
      count++;
      if (count >= 400) break;
    }
    if (count == 0) return;
    await batch.commit();
  }

  static Future<void> _updateStatus(String ideaId, IdeaStatus nextStatus) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    final IdeaStatus current = IdeaStatus.fromRaw((doc.data()!['status'] as String?) ?? 'submitted');
    if (nextStatus == IdeaStatus.shortlisted && !IdeaStatusHelpers.canShortlistFrom(current)) return;
    if (nextStatus == IdeaStatus.rejected && !IdeaStatusHelpers.canRejectFrom(current)) return;
    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(<String, dynamic>{
      'status': nextStatus.value,
    });
  }
}
