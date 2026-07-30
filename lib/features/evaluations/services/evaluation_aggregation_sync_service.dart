import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/score_model.dart';
import '../../../utils/firestore_utils.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/models/idea_model.dart';
import 'evaluation_aggregation_service.dart';
import 'evaluation_settings_service.dart';
import '../../org_settings/services/org_settings_service.dart';

/// Syncs evaluation aggregates onto ideas and advances lifecycle when complete.
abstract final class EvaluationAggregationSyncService {
  EvaluationAggregationSyncService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> syncIdea({
    required String ideaId,
    required String orgId,
  }) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return;

    final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!ideaDoc.exists || ideaDoc.data() == null) return;

    final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
    final int requiredEvaluations = EvaluationSettingsService.requiredJudgeEvaluations(orgId);

    final QuerySnapshot<Map<String, dynamic>> scoreSnap = await _db
        .collection(FirestoreUtils.hkzScores)
        .where('orgId', isEqualTo: orgId)
        .where('ideaId', isEqualTo: id)
        .get();
    final List<ScoreModel> scores = scoreSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => ScoreModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    final IdeaEvaluationAggregate aggregate = EvaluationAggregationService.computeFromScores(scores);
    final Map<String, List<String>> judgesByIdea = await EvaluationAssignmentService.assignedJudgesByIdea(
      orgId: orgId,
      ideaIds: <String>[id],
    );
    final Set<String> assignedJudges = judgesByIdea[id]?.toSet() ?? <String>{};
    final Set<String> scoredJudges = scores.map((ScoreModel s) => s.judgeId.trim()).where((String j) => j.isNotEmpty).toSet();

    IdeaStatus? nextStatus;
    if (assignedJudges.isNotEmpty && aggregate.hasScores) {
      if (aggregate.totalEvaluators >= requiredEvaluations &&
          (idea.status == IdeaStatus.submitted ||
              idea.status == IdeaStatus.underEvaluation ||
              idea.status == IdeaStatus.evaluated)) {
        nextStatus = IdeaStatus.readyForShortlisting;
      } else if (idea.status == IdeaStatus.readyForShortlisting &&
          aggregate.totalEvaluators < requiredEvaluations) {
        // Threshold was raised after ideas became ready — demote so shortlist
        // stays gated by the live Evaluation Configuration.
        nextStatus = IdeaStatus.evaluated;
      } else if (assignedJudges.every(scoredJudges.contains) &&
          (idea.status == IdeaStatus.underEvaluation || idea.status == IdeaStatus.submitted)) {
        nextStatus = IdeaStatus.evaluated;
      } else if (idea.status == IdeaStatus.submitted) {
        nextStatus = IdeaStatus.underEvaluation;
      }
    }

    final Map<String, dynamic> patch = <String, dynamic>{
      ...aggregate.toFirestoreFields(),
      if (nextStatus != null) 'status': nextStatus.value,
    };
    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(patch);
  }

  /// Re-applies [requiredJudgeEvaluations] to existing ideas so Evaluation
  /// Results shortlist actions reflect config changes without waiting for a
  /// new judge score submission.
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
      final bool candidate = idea.status == IdeaStatus.submitted ||
          idea.status == IdeaStatus.underEvaluation ||
          idea.status == IdeaStatus.evaluated ||
          idea.status == IdeaStatus.readyForShortlisting;
      if (candidate) ideaIds.add(idea.ideaId);
    }

    // Bound concurrency so large orgs don't open hundreds of Firestore ops at once.
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

  static Future<void> markUnderEvaluation({
    required String ideaId,
  }) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    final IdeaStatus status = IdeaStatus.fromRaw((doc.data()!['status'] as String?) ?? 'submitted');
    if (status != IdeaStatus.submitted) return;
    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(<String, dynamic>{
      'status': IdeaStatus.underEvaluation.value,
    });
  }
}
