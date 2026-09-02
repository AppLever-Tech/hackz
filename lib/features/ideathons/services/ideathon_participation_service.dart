import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../payment/models/payment_model.dart';
import '../models/ideathon_participation.dart';
import '../models/ideathon_participation_status.dart';

/// CRUD for Idea ↔ Ideathon membership documents.
abstract final class IdeathonParticipationService {
  IdeathonParticipationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreUtils.hkzIdeathonParticipations);

  /// Adds ideas as Ideathon members. [IdeaStatus] is untouched.
  ///
  /// Callers must only pass ideas whose idea-level payment is already verified
  /// (eligibility). This event's payment status starts pending until an
  /// event-scoped payment record exists for this [ideathonId].
  static Future<List<IdeathonParticipation>> createForIdeathon({
    required String orgId,
    required String ideathonId,
    required List<String> ideaIds,
    WriteBatch? batch,
  }) async {
    final String org = orgId.trim();
    final String eventId = ideathonId.trim();
    if (org.isEmpty || eventId.isEmpty || ideaIds.isEmpty) {
      return const <IdeathonParticipation>[];
    }

    final DateTime now = DateTime.now();
    final WriteBatch writeBatch = batch ?? _db.batch();
    final List<IdeathonParticipation> created = <IdeathonParticipation>[];

    for (final String rawIdeaId in ideaIds) {
      final String ideaId = rawIdeaId.trim();
      if (ideaId.isEmpty) continue;
      final DocumentReference<Map<String, dynamic>> ref = _col.doc();
      final IdeathonParticipation participation = IdeathonParticipation(
        participationId: ref.id,
        ideathonId: eventId,
        ideaId: ideaId,
        orgId: org,
        paymentStatus: PaymentRecordStatus.pending,
        participationStatus: IdeathonParticipationStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      writeBatch.set(ref, participation.toMap());
      created.add(participation);
    }

    if (batch == null) await writeBatch.commit();
    return created;
  }

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

  static Future<void> deleteForIdeathonIdeas({
    required String ideathonId,
    required Iterable<String> ideaIds,
  }) async {
    final Set<String> remove = ideaIds.map((String id) => id.trim()).where((String id) => id.isNotEmpty).toSet();
    if (remove.isEmpty) return;
    final List<IdeathonParticipation> existing = await listByIdeathon(ideathonId);
    final WriteBatch batch = _db.batch();
    var wrote = false;
    for (final IdeathonParticipation participation in existing) {
      if (!remove.contains(participation.ideaId.trim())) continue;
      batch.delete(_col.doc(participation.participationId));
      wrote = true;
    }
    if (wrote) await batch.commit();
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
