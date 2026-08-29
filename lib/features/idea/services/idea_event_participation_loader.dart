import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../evaluations/models/score_model.dart';
import '../../ideathons/models/ideathon_model.dart';
import '../../ideathons/services/ideathon_participation_service.dart';
import '../models/idea_event_participation_summary.dart';

/// Loads event membership for ideas without treating score/payment as idea state.
abstract final class IdeaEventParticipationLoader {
  IdeaEventParticipationLoader._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<IdeaEventParticipationSummary>> loadForIdea({
    required String ideaId,
    required String orgId,
  }) async {
    final Map<String, List<IdeaEventParticipationSummary>> byIdea = await loadByOrg(
      orgId: orgId,
      ideaIds: <String>{ideaId},
      includeScores: true,
    );
    return byIdea[ideaId.trim()] ?? const <IdeaEventParticipationSummary>[];
  }

  static Future<Map<String, List<IdeaEventParticipationSummary>>> loadByOrg({
    required String orgId,
    required Set<String> ideaIds,
    bool includeScores = false,
  }) async {
    final String org = orgId.trim();
    final Set<String> ids = ideaIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toSet();
    if (org.isEmpty || ids.isEmpty) return <String, List<IdeaEventParticipationSummary>>{};

    final participations = await IdeathonParticipationService.listByOrg(org);
    final relevant = participations.where((p) => ids.contains(p.ideaId.trim())).toList(growable: false);
    if (relevant.isEmpty) return <String, List<IdeaEventParticipationSummary>>{};

    final Set<String> eventIds = relevant.map((p) => p.ideathonId.trim()).where((id) => id.isNotEmpty).toSet();
    final Map<String, String> names = await _eventNames(orgId: org, eventIds: eventIds);
    final Map<String, _EventScore> scores = includeScores
        ? await _eventScores(orgId: org, ideaIds: ids, eventIds: eventIds)
        : const <String, _EventScore>{};

    final Map<String, List<IdeaEventParticipationSummary>> out = <String, List<IdeaEventParticipationSummary>>{};
    for (final participation in relevant) {
      final String ideaId = participation.ideaId.trim();
      final String eventId = participation.ideathonId.trim();
      if (ideaId.isEmpty || eventId.isEmpty) continue;
      final _EventScore? score = scores['$ideaId|$eventId'];
      out.putIfAbsent(ideaId, () => <IdeaEventParticipationSummary>[]).add(
        IdeaEventParticipationSummary(
          eventId: eventId,
          eventName: names[eventId]?.trim().isNotEmpty == true ? names[eventId]!.trim() : eventId,
          paymentStatus: participation.paymentStatus,
          evaluated: score != null,
          eventScore: score?.average,
        ),
      );
    }
    for (final List<IdeaEventParticipationSummary> list in out.values) {
      list.sort((a, b) => a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase()));
    }
    return out;
  }

  static Future<Map<String, String>> _eventNames({
    required String orgId,
    required Set<String> eventIds,
  }) async {
    if (eventIds.isEmpty) return const <String, String>{};
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestoreUtils.hkzIdeathons).where('orgId', isEqualTo: orgId).get();
    final Map<String, String> names = <String, String>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final IdeathonModel event = IdeathonModel.fromMap(doc.id, doc.data());
      final String id = event.ideathonId.trim().isEmpty ? doc.id.trim() : event.ideathonId.trim();
      if (!eventIds.contains(id)) continue;
      names[id] = event.name.trim();
    }
    return names;
  }

  static Future<Map<String, _EventScore>> _eventScores({
    required String orgId,
    required Set<String> ideaIds,
    required Set<String> eventIds,
  }) async {
    if (ideaIds.isEmpty || eventIds.isEmpty) return const <String, _EventScore>{};
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestoreUtils.hkzScores).where('orgId', isEqualTo: orgId).get();
    final Map<String, List<double>> grouped = <String, List<double>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final ScoreModel score = ScoreModel.fromMap(doc.id, doc.data());
      final String eventId = score.ideathonId.trim();
      final String ideaId = score.ideaId.trim();
      if (eventId.isEmpty || !eventIds.contains(eventId) || !ideaIds.contains(ideaId)) continue;
      grouped.putIfAbsent('$ideaId|$eventId', () => <double>[]).add(score.score);
    }
    return grouped.map(
      (String key, List<double> values) => MapEntry<String, _EventScore>(
        key,
        _EventScore(values.reduce((a, b) => a + b) / values.length),
      ),
    );
  }
}

class _EventScore {
  const _EventScore(this.average);
  final double average;
}
