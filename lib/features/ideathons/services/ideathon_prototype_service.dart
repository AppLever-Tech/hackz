import 'package:cloud_firestore/cloud_firestore.dart';

import '../../evaluations/models/score_model.dart';
import '../../../utils/firestore_utils.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/services/idea_status_helpers.dart';
import 'ideathon_settings_service.dart';

abstract final class IdeathonPrototypeService {
  IdeathonPrototypeService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<double?> averageIdeathonScore({
    required String orgId,
    required String ideaId,
    required String ideathonId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzScores)
        .where('orgId', isEqualTo: orgId.trim())
        .where('ideaId', isEqualTo: ideaId.trim())
        .where('ideathonId', isEqualTo: ideathonId.trim())
        .get();
    if (snap.docs.isEmpty) return null;
    final List<double> scores = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            ScoreModel.fromMap(doc.id, doc.data()).normalizedScore ?? 0)
        .toList(growable: false);
    if (scores.isEmpty) return null;
    return scores.reduce((double a, double b) => a + b) / scores.length;
  }

  static Future<void> applyAutomaticSelection({
    required String ideathonId,
    required String ideaId,
    required String orgId,
  }) async {
    await IdeathonSettingsService.ensureLoaded(orgId: orgId);
    final double threshold = IdeathonSettingsService.prototypeSelectionThresholdPercent(orgId);
    final double? avg = await averageIdeathonScore(
      orgId: orgId,
      ideaId: ideaId,
      ideathonId: ideathonId,
    );
    if (avg == null || avg < threshold) return;
    await selectPrototype(ideaId: ideaId);
  }

  static Future<void> selectPrototype({required String ideaId}) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    final IdeaStatus current = IdeaStatus.fromRaw((doc.data()!['status'] as String?) ?? '');
    if (!IdeaStatusHelpers.canSelectPrototypeFrom(current)) return;
    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(<String, dynamic>{
      'status': IdeaStatus.prototypeSelected.value,
    });
  }

  static Future<void> removePrototype({required String ideaId}) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    if (IdeaStatus.fromRaw((doc.data()!['status'] as String?) ?? '') != IdeaStatus.prototypeSelected) {
      return;
    }
    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(<String, dynamic>{
      'status': IdeaStatus.ideathonEvaluated.value,
    });
  }
}
