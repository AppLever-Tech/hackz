import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../payment/models/payment_model.dart';
import '../models/ideathon_participation.dart';
import '../models/ideathon_participation_status.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// CRUD for Idea ↔ Ideathon membership documents.
abstract final class IdeathonParticipationService {
  IdeathonParticipationService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreUtils.hkzIdeathonParticipations);

  /// Pending membership so Event Payments can show the canonical payment.
  /// Does not add the idea to the event Ideas roster — that happens on confirm.
  static Future<IdeathonParticipation> ensurePending({
    required String orgId,
    required String ideathonId,
    required String ideaId,
  }) async {
    final String eventId = ideathonId.trim();
    final String idea = ideaId.trim();
    final String org = orgId.trim();
    if (eventId.isEmpty || idea.isEmpty) {
      throw StateError('Event and idea are required.');
    }

    final List<IdeathonParticipation> forIdea = await listByIdea(idea);
    for (final IdeathonParticipation row in forIdea) {
      if (row.ideathonId.trim() == eventId) continue;
      if (row.paymentStatus == PaymentRecordStatus.verified) {
        throw StateError('This idea is already confirmed for another event.');
      }
      await _col.doc(row.participationId).delete();
    }

    final IdeathonParticipation? existing = await fetchByIdeathonAndIdea(
      ideathonId: eventId,
      ideaId: idea,
    );
    if (existing != null) {
      if (existing.paymentStatus == PaymentRecordStatus.verified) {
        return existing;
      }
      if (existing.paymentStatus != PaymentRecordStatus.pending) {
        await syncPaymentStatus(
          participationId: existing.participationId,
          paymentStatus: PaymentRecordStatus.pending,
        );
        return existing.copyWith(
          paymentStatus: PaymentRecordStatus.pending,
          updatedAt: DateTime.now(),
        );
      }
      return existing;
    }

    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> ref = _col.doc();
    final IdeathonParticipation participation = IdeathonParticipation(
      participationId: ref.id,
      ideathonId: eventId,
      ideaId: idea,
      orgId: org,
      paymentStatus: PaymentRecordStatus.pending,
      participationStatus: IdeathonParticipationStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(participation.toMap());
    return participation;
  }

  static Future<IdeathonParticipation?> fetchById(String participationId) async {
    final String id = participationId.trim();
    if (id.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return IdeathonParticipation.fromMap(doc.id, doc.data()!);
  }

  static Future<IdeathonParticipation?> fetchByIdeathonAndIdea({
    required String ideathonId,
    required String ideaId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col
        .where('ideathonId', isEqualTo: ideathonId.trim())
        .where('ideaId', isEqualTo: ideaId.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final QueryDocumentSnapshot<Map<String, dynamic>> doc = snap.docs.first;
    return IdeathonParticipation.fromMap(doc.id, doc.data());
  }

  static Future<List<IdeathonParticipation>> listByIdeathon(String ideathonId) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('ideathonId', isEqualTo: ideathonId.trim()).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            IdeathonParticipation.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  static Future<List<IdeathonParticipation>> listByOrg(String orgId) async {
    final String id = orgId.trim();
    if (id.isEmpty) return const <IdeathonParticipation>[];
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('orgId', isEqualTo: id).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            IdeathonParticipation.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  static Future<List<IdeathonParticipation>> listByIdea(String ideaId) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('ideaId', isEqualTo: ideaId.trim()).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            IdeathonParticipation.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  /// The Idea's event membership — source of truth for payment scoping.
  static Future<IdeathonParticipation?> fetchForIdea(String ideaId) async {
    final List<IdeathonParticipation> rows = await listByIdea(ideaId);
    IdeathonParticipation? verified;
    IdeathonParticipation? pending;
    for (final IdeathonParticipation row in rows) {
      if (row.ideathonId.trim().isEmpty) continue;
      if (row.paymentStatus == PaymentRecordStatus.verified) {
        verified = row;
        break;
      }
      pending ??= row;
    }
    return verified ?? pending;
  }

  /// Mirrors idea payment status onto membership rows (optional sync).
  static Future<void> syncPaymentStatus({
    required String participationId,
    required PaymentRecordStatus paymentStatus,
  }) async {
    final String id = participationId.trim();
    if (id.isEmpty) return;
    await _col.doc(id).update(<String, dynamic>{
      'paymentStatus': paymentStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
