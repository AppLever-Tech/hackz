import 'package:cloud_firestore/cloud_firestore.dart';

import '../../evaluations/models/score_model.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../models/ideathon_model.dart';
import 'ideathon_service.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Syncs Ideathon-scoped evaluation completion.
///
/// Does **not** mutate IdeaStatus. Does not auto-select winners or complete the event.
abstract final class IdeathonEvaluationSyncService {
  IdeathonEvaluationSyncService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<void> syncIdeathonIdea({
    required String ideathonId,
    required String ideaId,
    required String orgId,
  }) async {
    final String iid = ideathonId.trim();
    final String id = ideaId.trim();
    if (iid.isEmpty || id.isEmpty) return;

    final Map<String, List<String>> judgesByIdea = await _assignedIdeathonJudges(
      orgId: orgId,
      ideathonId: iid,
      ideaIds: <String>[id],
    );
    final Set<String> assigned = judgesByIdea[id]?.toSet() ?? <String>{};
    if (assigned.isEmpty) return;

    final QuerySnapshot<Map<String, dynamic>> scoresSnap = await _db
        .collection(FirestoreUtils.hkzScores)
        .where('orgId', isEqualTo: orgId)
        .where('ideaId', isEqualTo: id)
        .where('ideathonId', isEqualTo: iid)
        .get();
    final Set<String> scored = scoresSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            ScoreModel.fromMap(doc.id, doc.data()).judgeId.trim())
        .where((String j) => j.isNotEmpty)
        .toSet();

    if (!assigned.every(scored.contains)) return;

    // Phase 6: record evaluation completion only — no automatic prototype/winner selection.
  }

  static Future<void> syncIdeathonCompletion(String ideathonId) async {
    final IdeathonModel? ideathon = await _fetchIdeathon(ideathonId);
    if (ideathon == null) return;
    await IdeathonService.markInProgressIfNeeded(ideathonId);
    // Completion is Department Admin-owned. Schedule and 100% scores do not auto-complete.
  }

  static Future<Map<String, List<String>>> _assignedIdeathonJudges({
    required String orgId,
    required String ideathonId,
    required List<String> ideaIds,
  }) async {
    if (ideaIds.isEmpty) return const <String, List<String>>{};
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzEvaluationAssignments)
        .where('orgId', isEqualTo: orgId.trim())
        .where('ideathonId', isEqualTo: ideathonId.trim())
        .get();
    final Map<String, List<String>> byIdea = <String, List<String>>{
      for (final String id in ideaIds) id: <String>[],
    };
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final EvaluationAssignmentModel assignment = EvaluationAssignmentModel.fromMap(doc.id, doc.data());
      if (assignment.status != EvaluationAssignmentStatus.active) continue;
      final List<String>? list = byIdea[assignment.ideaId];
      if (list == null) continue;
      final String judgeId = assignment.judgeId.trim();
      if (judgeId.isNotEmpty && !list.contains(judgeId)) list.add(judgeId);
    }
    return byIdea;
  }

  static Future<IdeathonModel?> _fetchIdeathon(String ideathonId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeathons).doc(ideathonId.trim()).get();
    if (!doc.exists || doc.data() == null) return null;
    return IdeathonModel.fromMap(doc.id, doc.data()!);
  }
}
