import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/score_model.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/models/idea_model.dart';
import '../models/ideathon_model.dart';
import 'ideathon_prototype_service.dart';

/// Advances ideathon idea lifecycle when all assigned judges have scored.
abstract final class IdeathonEvaluationSyncService {
  IdeathonEvaluationSyncService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> syncIdeathonIdea({
    required String ideathonId,
    required String ideaId,
    required String orgId,
  }) async {
    final String iid = ideathonId.trim();
    final String id = ideaId.trim();
    if (iid.isEmpty || id.isEmpty) return;

    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) return;
    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    if (idea.status != IdeaStatus.ideathonAssigned) return;

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

    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(<String, dynamic>{
      'status': IdeaStatus.ideathonEvaluated.value,
    });

    await IdeathonPrototypeService.applyAutomaticSelection(
      ideathonId: iid,
      ideaId: id,
      orgId: orgId,
    );
  }

  static Future<void> syncIdeathonCompletion(String ideathonId) async {
    final IdeathonModel? ideathon = await _fetchIdeathon(ideathonId);
    if (ideathon == null) return;

    bool allEvaluated = true;
    for (final snapshot in ideathon.ideas) {
      final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
          await _db.collection(FirestoreUtils.hkzIdeas).doc(snapshot.ideaId).get();
      if (!ideaDoc.exists || ideaDoc.data() == null) {
        allEvaluated = false;
        continue;
      }
      final IdeaStatus status = IdeaStatus.fromRaw((ideaDoc.data()!['status'] as String?) ?? '');
      if (status != IdeaStatus.ideathonEvaluated && status != IdeaStatus.prototypeSelected) {
        allEvaluated = false;
      }
    }
    if (allEvaluated) {
      await _db.collection(FirestoreUtils.hkzIdeathons).doc(ideathon.ideathonId).update(<String, dynamic>{
        'status': 'completed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<Map<String, List<String>>> _assignedIdeathonJudges({
    required String orgId,
    required String ideathonId,
    required List<String> ideaIds,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzEvaluationAssignments)
        .where('orgId', isEqualTo: orgId)
        .where('ideathonId', isEqualTo: ideathonId)
        .where('status', isEqualTo: EvaluationAssignmentStatus.active.value)
        .get();
    final Set<String> filter = ideaIds.toSet();
    final Map<String, List<String>> byIdea = <String, List<String>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final EvaluationAssignmentModel assignment =
          EvaluationAssignmentModel.fromMap(doc.id, doc.data());
      if (!filter.contains(assignment.ideaId)) continue;
      byIdea.putIfAbsent(assignment.ideaId, () => <String>[]).add(assignment.judgeId);
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
