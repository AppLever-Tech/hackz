import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../payment/models/payment_model.dart';
import '../models/ideathon_participation.dart';
import '../models/ideathon_participation_status.dart';

/// CRUD for Idea ↔ Ideathon participation documents (event pool + registration).
abstract final class IdeathonParticipationService {
  IdeathonParticipationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreUtils.hkzIdeathonParticipations);

  /// Adds ideas to the Ideathon **event pool** (not registration).
  ///
  /// Creates [IdeathonParticipationStatus.inPool] rows. [IdeaStatus] is untouched.
  /// Registration happens later when faculty payment is completed and verified.
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
        participationStatus: IdeathonParticipationStatus.inPool,
        createdAt: now,
        updatedAt: now,
      );
      writeBatch.set(ref, participation.toMap());
      created.add(participation);
    }

    if (batch == null) await writeBatch.commit();
    return created;
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

  /// Ideas in the event pool for an Ideathon (includes unpaid / unregistered).
  static Future<List<IdeathonParticipation>> listPoolByIdeathon(String ideathonId) {
    return listByIdeathon(ideathonId);
  }

  /// Ideas registered for the Ideathon (payment verified / ready for execution).
  static Future<List<IdeathonParticipation>> listRegisteredByIdeathon(String ideathonId) async {
    final List<IdeathonParticipation> all = await listByIdeathon(ideathonId);
    return all.where((IdeathonParticipation p) => p.isRegistered).toList(growable: false);
  }

  static Future<List<IdeathonParticipation>> listByIdea(String ideaId) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('ideaId', isEqualTo: ideaId.trim()).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            IdeathonParticipation.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  /// Faculty payment submitted — still not registered until verified.
  static Future<void> markPaymentPending({
    required String participationId,
  }) async {
    final String id = participationId.trim();
    if (id.isEmpty) return;
    await _col.doc(id).update(<String, dynamic>{
      'paymentStatus': PaymentRecordStatus.pending.value,
      'participationStatus': IdeathonParticipationStatus.paymentPending.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Payment verified — idea is registered for this Ideathon.
  static Future<void> markPaymentVerified({
    required String participationId,
  }) async {
    final String id = participationId.trim();
    if (id.isEmpty) return;
    await _col.doc(id).update(<String, dynamic>{
      'paymentStatus': PaymentRecordStatus.verified.value,
      'participationStatus': IdeathonParticipationStatus.readyForExecution.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Payment rejected — return to event pool (not registered).
  static Future<void> markPaymentRejected({
    required String participationId,
  }) async {
    final String id = participationId.trim();
    if (id.isEmpty) return;
    await _col.doc(id).update(<String, dynamic>{
      'paymentStatus': PaymentRecordStatus.rejected.value,
      'participationStatus': IdeathonParticipationStatus.inPool.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
