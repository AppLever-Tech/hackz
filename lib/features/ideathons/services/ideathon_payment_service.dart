import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/common_helpers.dart';
import '../../../utils/firestore_utils.dart';
import '../../idea/models/idea_model.dart';
import '../../payment/models/payment_model.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_participation.dart';
import 'ideathon_participation_service.dart';
import 'ideathon_service.dart';

/// One Ideathon participation row for the payment workspace.
class IdeathonPaymentRow {
  const IdeathonPaymentRow({
    required this.participation,
    required this.ideaTitle,
    required this.teamName,
    required this.teamId,
    required this.payerName,
    required this.payerId,
    this.payment,
  });

  final IdeathonParticipation participation;
  final String ideaTitle;
  final String teamName;
  final String teamId;
  final String payerName;
  final String payerId;
  final PaymentModel? payment;

  String get ideaId => participation.ideaId;
  PaymentRecordStatus get displayPaymentStatus =>
      payment?.status ?? participation.paymentStatus;
  bool get isReadyForExecution =>
      displayPaymentStatus == PaymentRecordStatus.verified && participation.isActive;
  bool get canVerify =>
      payment != null && displayPaymentStatus == PaymentRecordStatus.pending;
  bool get canReject =>
      payment != null && displayPaymentStatus == PaymentRecordStatus.pending;
  bool get isException => displayPaymentStatus == PaymentRecordStatus.rejected;
}

class IdeathonPaymentMetrics {
  const IdeathonPaymentMetrics({
    required this.totalIdeas,
    required this.paymentPending,
    required this.paymentCompleted,
    required this.paymentException,
  });

  final int totalIdeas;
  final int paymentPending;
  final int paymentCompleted;
  final int paymentException;
}

class IdeathonPaymentWorkspaceViewModel {
  const IdeathonPaymentWorkspaceViewModel({
    required this.ideathon,
    required this.rows,
    required this.metrics,
  });

  final IdeathonModel ideathon;
  final List<IdeathonPaymentRow> rows;
  final IdeathonPaymentMetrics metrics;
}

/// Loads and mutates Ideathon participation payment readiness.
abstract final class IdeathonPaymentService {
  IdeathonPaymentService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<IdeathonPaymentWorkspaceViewModel> load(String ideathonId) async {
    final String id = ideathonId.trim();
    if (id.isEmpty) throw ArgumentError('ideathonId must be non-empty');

    final IdeathonModel? ideathon = await IdeathonService.fetchById(id);
    if (ideathon == null) throw StateError('Ideathon not found');

    final List<IdeathonParticipation> participations =
        await IdeathonParticipationService.listByIdeathon(id);

    final QuerySnapshot<Map<String, dynamic>> paymentSnap = await _db
        .collection(FirestoreUtils.hkzPayments)
        .where('ideathonId', isEqualTo: id)
        .get();
    final Map<String, PaymentModel> byParticipationId = <String, PaymentModel>{};
    final Map<String, PaymentModel> byIdeaId = <String, PaymentModel>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in paymentSnap.docs) {
      final PaymentModel payment = PaymentModel.fromMap(doc.id, doc.data());
      if (payment.participationId.trim().isNotEmpty) {
        byParticipationId[payment.participationId.trim()] = payment;
      }
      if (payment.ideaId.trim().isNotEmpty) {
        byIdeaId.putIfAbsent(payment.ideaId.trim(), () => payment);
      }
    }

    final List<IdeathonPaymentRow> rows = await Future.wait(
      participations.map(
        (IdeathonParticipation participation) => _loadRow(
          ideathon: ideathon,
          participation: participation,
          byParticipationId: byParticipationId,
          byIdeaId: byIdeaId,
        ),
      ),
    );

    rows.sort((IdeathonPaymentRow a, IdeathonPaymentRow b) {
      final int statusCmp =
          _statusRank(a.displayPaymentStatus).compareTo(_statusRank(b.displayPaymentStatus));
      if (statusCmp != 0) return statusCmp;
      return a.ideaTitle.toLowerCase().compareTo(b.ideaTitle.toLowerCase());
    });

    return IdeathonPaymentWorkspaceViewModel(
      ideathon: ideathon,
      rows: rows,
      metrics: _metrics(rows),
    );
  }

  /// Ensures the payment is stamped with participation linkage, then verifies.
  static Future<void> verifyRow({
    required IdeathonPaymentRow row,
    required UserModel coordinator,
  }) async {
    final PaymentModel? payment = row.payment;
    if (payment == null) {
      throw StateError('No payment record available to verify.');
    }
    await _ensurePaymentLinked(payment: payment, participation: row.participation);
    await FirestoreUtils.verifyIdeaPayment(
      paymentId: payment.paymentId,
      coordinatorId: coordinator.userId,
    );
  }

  static Future<void> rejectRow({
    required IdeathonPaymentRow row,
    required UserModel coordinator,
    String? remarks,
  }) async {
    final PaymentModel? payment = row.payment;
    if (payment == null) {
      throw StateError('No payment record available to reject.');
    }
    await _ensurePaymentLinked(payment: payment, participation: row.participation);
    await FirestoreUtils.rejectIdeaPayment(
      paymentId: payment.paymentId,
      coordinatorId: coordinator.userId,
      remarks: remarks,
    );
  }

  /// Syncs membership payment mirror when the idea payment is already verified.
  static Future<void> markParticipationReady(IdeathonPaymentRow row) async {
    if (row.displayPaymentStatus != PaymentRecordStatus.verified) {
      throw StateError('Payment must be verified first.');
    }
    await IdeathonParticipationService.syncPaymentStatus(
      participationId: row.participation.participationId,
      paymentStatus: PaymentRecordStatus.verified,
    );
  }

  static Future<void> _ensurePaymentLinked({
    required PaymentModel payment,
    required IdeathonParticipation participation,
  }) async {
    final String pid = participation.participationId.trim();
    final String iid = participation.ideathonId.trim();
    if (pid.isEmpty) return;
    final bool needsStamp = payment.participationId.trim().isEmpty ||
        payment.ideathonId.trim().isEmpty ||
        payment.participationId.trim() != pid;
    if (!needsStamp) return;
    await _db.collection(FirestoreUtils.hkzPayments).doc(payment.paymentId).update(<String, dynamic>{
      'participationId': pid,
      'ideathonId': iid,
    });
  }

  static IdeathonPaymentMetrics _metrics(List<IdeathonPaymentRow> rows) {
    int pending = 0;
    int completed = 0;
    int exception = 0;
    for (final IdeathonPaymentRow row in rows) {
      switch (row.displayPaymentStatus) {
        case PaymentRecordStatus.pending:
          pending++;
        case PaymentRecordStatus.verified:
          completed++;
        case PaymentRecordStatus.rejected:
          exception++;
      }
    }
    return IdeathonPaymentMetrics(
      totalIdeas: rows.length,
      paymentPending: pending,
      paymentCompleted: completed,
      paymentException: exception,
    );
  }

  static int _statusRank(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.pending => 0,
      PaymentRecordStatus.rejected => 1,
      PaymentRecordStatus.verified => 2,
    };
  }

  static Future<IdeathonPaymentRow> _loadRow({
    required IdeathonModel ideathon,
    required IdeathonParticipation participation,
    required Map<String, PaymentModel> byParticipationId,
    required Map<String, PaymentModel> byIdeaId,
  }) async {
    PaymentModel? payment = byParticipationId[participation.participationId];
    payment ??= byIdeaId[participation.ideaId];

    final String ideaId = participation.ideaId.trim();
    late final IdeaModel? idea;
    if (payment == null && ideaId.isNotEmpty) {
      final Future<DocumentSnapshot<Map<String, dynamic>>> payDocFuture =
          _db.collection(FirestoreUtils.hkzPayments).doc(ideaId).get();
      final Future<IdeaModel?> ideaFuture = _fetchIdea(ideaId);
      final DocumentSnapshot<Map<String, dynamic>> ideaPay = await payDocFuture;
      idea = await ideaFuture;
      if (ideaPay.exists && ideaPay.data() != null) {
        payment = PaymentModel.fromMap(ideaPay.id, ideaPay.data()!);
      }
    } else {
      idea = await _fetchIdea(ideaId);
    }

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

    return IdeathonPaymentRow(
      participation: participation,
      ideaTitle: ideaTitle.isEmpty ? participation.ideaId : ideaTitle,
      teamName: teamName.isEmpty ? '—' : teamName,
      teamId: teamId,
      payerName: payer == null ? (payerId.isEmpty ? '—' : payerId) : userDisplayName(payer),
      payerId: payerId,
      payment: payment,
    );
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
}
