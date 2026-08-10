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

  /// Adds paid ideas as Ideathon members. [IdeaStatus] is untouched.
  ///
  /// Callers must only pass ideas whose idea-level payment is already verified.
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
        paymentStatus: PaymentRecordStatus.verified,
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

  static Future<List<IdeathonParticipation>> listByIdea(String ideaId) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('ideaId', isEqualTo: ideaId.trim()).get();
    return snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            IdeathonParticipation.fromMap(doc.id, doc.data()))
        .toList(growable: false);
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
