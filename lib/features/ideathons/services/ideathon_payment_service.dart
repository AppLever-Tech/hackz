import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../events/models/event_kind.dart';
import '../../events/models/event_payment_entry.dart';
import '../../idea/models/idea_model.dart';
import '../../payment/models/payment_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/role_visibility_helpers.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_participation.dart';
import 'ideathon_participation_service.dart';
import 'ideathon_service.dart';

/// Ideathon adapter for Event Payments: participations + payments scoped to one eventId.
abstract final class IdeathonPaymentService {
  IdeathonPaymentService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<EventPaymentsViewModel> load(String eventId) async {
    final String id = eventId.trim();
    if (id.isEmpty) throw ArgumentError('eventId must be non-empty');

    final IdeathonModel? ideathon = await IdeathonService.fetchById(id);
    if (ideathon == null) throw StateError('Ideathon not found');

    final List<IdeathonParticipation> participations =
        await IdeathonParticipationService.listByIdeathon(id);

    final (Map<String, PaymentModel> byParticipationId, Map<String, PaymentModel> byIdeaId) =
        await _eventPayments(id);

    final List<EventPaymentEntry> entries = await Future.wait(
      participations.map(
        (IdeathonParticipation participation) => _loadEntry(
          ideathon: ideathon,
          participation: participation,
          eventId: id,
          byParticipationId: byParticipationId,
          byIdeaId: byIdeaId,
        ),
      ),
    );

    entries.sort((EventPaymentEntry a, EventPaymentEntry b) {
      final int statusCmp = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (statusCmp != 0) return statusCmp;
      return a.entryTitle.toLowerCase().compareTo(b.entryTitle.toLowerCase());
    });

    return EventPaymentsViewModel(
      eventId: id,
      kind: EventKind.ideathon,
      entries: entries,
      metrics: _metrics(entries),
    );
  }

  static Future<void> confirm({
    required String eventId,
    required EventPaymentEntry entry,
    required UserModel actor,
  }) async {
    final PaymentModel payment = _requireEventPayment(eventId: eventId, entry: entry);
    await FirestoreUtils.verifyIdeaPayment(
      paymentId: payment.paymentId,
      coordinatorId: actor.userId,
    );
  }

  static Future<void> markException({
    required String eventId,
    required EventPaymentEntry entry,
    required UserModel actor,
    String? remarks,
  }) async {
    final PaymentModel payment = _requireEventPayment(eventId: eventId, entry: entry);
    await FirestoreUtils.rejectIdeaPayment(
      paymentId: payment.paymentId,
      coordinatorId: actor.userId,
      remarks: remarks,
    );
  }

  static PaymentModel _requireEventPayment({
    required String eventId,
    required EventPaymentEntry entry,
  }) {
    final PaymentModel? payment = entry.payment;
    if (payment == null) {
      throw StateError('No payment record available for this event.');
    }
    if (!payment.belongsToEvent(eventId)) {
      throw StateError('Payment does not belong to this event.');
    }
    return payment;
  }

  /// Payments whose Firestore `ideathonId` equals [eventId]. Never idea-level docs.
  static Future<(Map<String, PaymentModel>, Map<String, PaymentModel>)> _eventPayments(
    String eventId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzPayments)
        .where('ideathonId', isEqualTo: eventId)
        .get();
    final Map<String, PaymentModel> byParticipationId = <String, PaymentModel>{};
    final Map<String, PaymentModel> byIdeaId = <String, PaymentModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final PaymentModel payment = PaymentModel.fromMap(doc.id, doc.data());
      if (!payment.belongsToEvent(eventId)) continue;
      final String participationId = payment.participationId.trim();
      if (participationId.isNotEmpty) {
        byParticipationId.putIfAbsent(participationId, () => payment);
      }
      final String ideaId = payment.ideaId.trim();
      if (ideaId.isNotEmpty) {
        byIdeaId.putIfAbsent(ideaId, () => payment);
      }
    }
    return (byParticipationId, byIdeaId);
  }

  static Future<EventPaymentEntry> _loadEntry({
    required IdeathonModel ideathon,
    required IdeathonParticipation participation,
    required String eventId,
    required Map<String, PaymentModel> byParticipationId,
    required Map<String, PaymentModel> byIdeaId,
  }) async {
    PaymentModel? payment = byParticipationId[participation.participationId.trim()];
    payment ??= byIdeaId[participation.ideaId.trim()];
    if (payment != null && !payment.belongsToEvent(eventId)) {
      payment = null;
    }

    final String ideaId = participation.ideaId.trim();
    final IdeaModel? idea = await _fetchIdea(ideaId);

    String teamId = payment?.teamId.trim() ?? '';
    if (idea != null && idea.teamId.trim().isNotEmpty) {
      teamId = teamId.isEmpty ? idea.teamId.trim() : teamId;
    }

    final String payerId = (payment?.paidByStudentId.trim().isNotEmpty == true)
        ? payment!.paidByStudentId.trim()
        : (idea?.createdBy.trim() ?? '');
    final Future<String> teamNameFuture = _fetchTeamName(teamId);
    final Future<UserModel?> payerFuture =
        payerId.isEmpty ? Future<UserModel?>.value(null) : FirestoreUtils.fetchUser(payerId);
    String teamName = await teamNameFuture;
    final UserModel? payer = await payerFuture;

    String ideaTitle = idea?.ideaTitle.trim() ?? '';
    if (ideaTitle.isEmpty) {
      for (final snapshot in ideathon.ideas) {
        if (snapshot.ideaId == participation.ideaId) {
          ideaTitle = snapshot.ideaTitle;
          if (teamName.isEmpty) teamName = snapshot.teamName;
          break;
        }
      }
    }

    final PaymentRecordStatus status = payment?.status ?? PaymentRecordStatus.pending;
    final bool pending = payment != null && status == PaymentRecordStatus.pending;

    return EventPaymentEntry(
      entryId: ideaId,
      entryTitle: ideaTitle.isEmpty ? participation.ideaId : ideaTitle,
      teamId: teamId,
      teamName: teamName.isEmpty ? '—' : teamName,
      payerId: payerId,
      payerName: payer == null ? (payerId.isEmpty ? '—' : payerId) : userDisplayName(payer),
      payment: payment,
      status: status,
      canConfirm: pending,
      canMarkException: pending,
    );
  }

  static EventPaymentMetrics _metrics(List<EventPaymentEntry> entries) {
    int pending = 0;
    int confirmed = 0;
    int exceptions = 0;
    for (final EventPaymentEntry row in entries) {
      switch (row.status) {
        case PaymentRecordStatus.pending:
          pending++;
        case PaymentRecordStatus.verified:
          confirmed++;
        case PaymentRecordStatus.rejected:
          exceptions++;
      }
    }
    return EventPaymentMetrics(
      total: entries.length,
      confirmed: confirmed,
      pending: pending,
      exceptions: exceptions,
    );
  }

  static int _statusRank(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.pending => 0,
      PaymentRecordStatus.rejected => 1,
      PaymentRecordStatus.verified => 2,
    };
  }

  static Future<IdeaModel?> _fetchIdea(String ideaId) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return IdeaModel.fromMap(doc.id, doc.data()!);
  }

  static Future<String> _fetchTeamName(String teamId) async {
    final String id = teamId.trim();
    if (id.isEmpty) return '';
    final DocumentSnapshot<Map<String, dynamic>> teamDoc =
        await _db.collection(FirestoreUtils.hkzTeams).doc(id).get();
    if (!teamDoc.exists || teamDoc.data() == null) return '';
    return ((teamDoc.data()!['teamName'] as String?) ?? '').trim();
  }

  static bool actorCanManage(UserModel? actor) {
    if (actor == null) return false;
    return RoleVisibilityHelpers.canManageEventPayments(UserRole.fromCode(actor.role));
  }
}
