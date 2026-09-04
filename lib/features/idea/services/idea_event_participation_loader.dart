import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../evaluations/models/score_model.dart';
import '../../ideathons/models/ideathon_model.dart';
import '../../ideathons/models/ideathon_status.dart';
import '../../ideathons/models/ideathon_type.dart';
import '../../ideathons/services/ideathon_participation_service.dart';
import '../models/idea_event_participation_summary.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Loads event membership for ideas without treating score/payment as idea state.
abstract final class IdeaEventParticipationLoader {
  IdeaEventParticipationLoader._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

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
    final Map<String, IdeathonModel> events = await _eventsById(orgId: org, eventIds: eventIds);
    final Map<String, _EventScore> scores = includeScores
        ? await _eventScores(orgId: org, ideaIds: ids, eventIds: eventIds)
        : const <String, _EventScore>{};

    final Map<String, List<IdeaEventParticipationSummary>> out = <String, List<IdeaEventParticipationSummary>>{};
    for (final participation in relevant) {
      final String ideaId = participation.ideaId.trim();
      final String eventId = participation.ideathonId.trim();
      if (ideaId.isEmpty || eventId.isEmpty) continue;
      final IdeathonModel? event = events[eventId];
      final _EventScore? score = scores['$ideaId|$eventId'];
      out.putIfAbsent(ideaId, () => <IdeaEventParticipationSummary>[]).add(
        IdeaEventParticipationSummary(
          eventId: eventId,
          eventName: event?.name.trim().isNotEmpty == true ? event!.name.trim() : eventId,
          paymentStatus: participation.paymentStatus,
          evaluated: score != null,
          eventScore: score?.average,
          eventType: event?.ideathonType ?? IdeathonType.internal,
          eventStatus: event?.status ?? IdeathonStatus.draft,
          startDateTime: event?.startDateTime,
          endDateTime: event?.endDateTime,
        ),
      );
    }
    for (final List<IdeaEventParticipationSummary> list in out.values) {
      list.sort((a, b) => a.eventName.toLowerCase().compareTo(b.eventName.toLowerCase()));
    }
    return out;
  }

  static Future<Map<String, IdeathonModel>> _eventsById({
    required String orgId,
    required Set<String> eventIds,
  }) async {
    if (eventIds.isEmpty) return const <String, IdeathonModel>{};
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _db.collection(FirestoreUtils.hkzIdeathons).where('orgId', isEqualTo: orgId).get();
    final Map<String, IdeathonModel> events = <String, IdeathonModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final IdeathonModel event = IdeathonModel.fromMap(doc.id, doc.data());
      final String id = event.ideathonId.trim().isEmpty ? doc.id.trim() : event.ideathonId.trim();
      if (!eventIds.contains(id)) continue;
      events[id] = event;
    }
    return events;
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
