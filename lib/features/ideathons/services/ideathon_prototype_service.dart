import 'package:cloud_firestore/cloud_firestore.dart';

import '../../evaluations/models/score_model.dart';
import '../../../utils/firestore_utils.dart';
import 'ideathon_settings_service.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Prototype selection helpers for Ideathon events.
///
/// Phase 2: does **not** mutate IdeaStatus. Phase 3 will store selection on
/// IdeathonParticipation / Ideathon event state.
abstract final class IdeathonPrototypeService {
  IdeathonPrototypeService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

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
    // Phase 3: record prototype selection on participation / event.
  }

  static Future<void> selectPrototype({required String ideaId}) async {
    // Phase 3: event-level prototype selection.
  }

  static Future<void> removePrototype({required String ideaId}) async {
    // Phase 3: event-level prototype selection.
  }
}
