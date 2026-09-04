import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/score_model.dart';
import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import 'evaluation_aggregation_service.dart';
import '../../org_settings/services/org_settings_service.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Syncs evaluation aggregates onto ideas.
///
/// Does **not** change [IdeaStatus] — Idea lifecycle is only draft/submitted.
/// Aggregate fields remain for the reusable evaluation framework (Phase 3 Ideathon evaluation).
abstract final class EvaluationAggregationSyncService {
  EvaluationAggregationSyncService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<void> syncIdea({
    required String ideaId,
    required String orgId,
  }) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return;

    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) return;

    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);

    final QuerySnapshot<Map<String, dynamic>> scoreSnap = await _db
        .collection(FirestoreUtils.hkzScores)
        .where('orgId', isEqualTo: orgId)
        .where('ideaId', isEqualTo: id)
        .get();
    // Ideathon scores must never influence Idea-level aggregates / pipeline results.
    final List<ScoreModel> scores = scoreSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => ScoreModel.fromMap(doc.id, doc.data()))
        .where((ScoreModel s) => !s.isIdeathonScore)
        .toList(growable: false);

    final IdeaEvaluationAggregate aggregate = EvaluationAggregationService.computeFromScores(scores);
    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(aggregate.toFirestoreFields());
  }

  /// Re-applies evaluation aggregates for submitted ideas in an org.
  static Future<void> reconcileOrg({required String orgId}) async {
    final String org = orgId.trim();
    if (org.isEmpty) return;

    await OrgSettingsService.instance.ensureLoaded(orgId: org);

    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzIdeas)
        .where('orgId', isEqualTo: org)
        .get();

    final List<String> ideaIds = <String>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
      if (idea.status == IdeaStatus.submitted || idea.hasEvaluationAggregate) {
        ideaIds.add(idea.ideaId);
      }
    }

    const int batchSize = 8;
    for (int i = 0; i < ideaIds.length; i += batchSize) {
      final List<String> chunk = ideaIds.sublist(
        i,
        i + batchSize > ideaIds.length ? ideaIds.length : i + batchSize,
      );
      await Future.wait<void>(
        chunk.map((String ideaId) => syncIdea(ideaId: ideaId, orgId: org)),
      );
    }
  }

}
