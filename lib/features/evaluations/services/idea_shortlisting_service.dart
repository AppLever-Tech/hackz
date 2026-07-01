import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';

/// Department-admin shortlisting workflow for ideas ready for shortlisting.
abstract final class IdeaShortlistingService {
  IdeaShortlistingService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> shortlistIdea(
    String ideaId, {
    required String shortlistedBy,
    String? remarks,
  }) async {
    await _updateStatus(
      ideaId,
      IdeaStatus.shortlisted,
      shortlistedBy: shortlistedBy,
      remarks: remarks,
    );
  }

  static Future<void> rejectIdea(String ideaId) async {
    await _updateStatus(ideaId, IdeaStatus.rejected);
  }

  static Future<void> shortlistMany(
    Iterable<String> ideaIds, {
    required String shortlistedBy,
    String? remarks,
  }) async {
    await _updateMany(
      ideaIds,
      IdeaStatus.shortlisted,
      shortlistedBy: shortlistedBy,
      remarks: remarks,
    );
  }

  static Future<void> rejectMany(Iterable<String> ideaIds) async {
    await _updateMany(ideaIds, IdeaStatus.rejected);
  }

  static Future<void> _updateMany(
    Iterable<String> ideaIds,
    IdeaStatus nextStatus, {
    String? shortlistedBy,
    String? remarks,
  }) async {
    final WriteBatch batch = _db.batch();
    var count = 0;
    for (final String raw in ideaIds) {
      final String id = raw.trim();
      if (id.isEmpty) continue;
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
      if (!doc.exists || doc.data() == null) continue;
      final IdeaStatus current = IdeaStatus.fromRaw((doc.data()!['status'] as String?) ?? 'submitted');
      if (nextStatus == IdeaStatus.shortlisted && !IdeaStatusHelpers.canShortlistFrom(current)) continue;
      if (nextStatus == IdeaStatus.rejected && !IdeaStatusHelpers.canRejectFrom(current)) continue;

      final Map<String, dynamic> patch = <String, dynamic>{'status': nextStatus.value};
      if (nextStatus == IdeaStatus.shortlisted && shortlistedBy != null) {
        patch[IdeaModel.fieldShortlistedBy] = shortlistedBy.trim();
        patch[IdeaModel.fieldShortlistedAt] = FieldValue.serverTimestamp();
        final String trimmedRemarks = (remarks ?? '').trim();
        if (trimmedRemarks.isNotEmpty) {
          patch[IdeaModel.fieldShortlistRemarks] = trimmedRemarks;
        }
      }

      batch.update(_db.collection(FirestoreUtils.hkzIdeas).doc(id), patch);
      count++;
      if (count >= 400) break;
    }
    if (count == 0) return;
    await batch.commit();
  }

  static Future<void> _updateStatus(
    String ideaId,
    IdeaStatus nextStatus, {
    String? shortlistedBy,
    String? remarks,
  }) async {
    final String id = ideaId.trim();
    if (id.isEmpty) return;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzIdeas).doc(id).get();
    if (!doc.exists || doc.data() == null) return;
    final IdeaStatus current = IdeaStatus.fromRaw((doc.data()!['status'] as String?) ?? 'submitted');
    if (nextStatus == IdeaStatus.shortlisted && !IdeaStatusHelpers.canShortlistFrom(current)) return;
    if (nextStatus == IdeaStatus.rejected && !IdeaStatusHelpers.canRejectFrom(current)) return;

    final Map<String, dynamic> patch = <String, dynamic>{'status': nextStatus.value};
    if (nextStatus == IdeaStatus.shortlisted && shortlistedBy != null) {
      patch[IdeaModel.fieldShortlistedBy] = shortlistedBy.trim();
      patch[IdeaModel.fieldShortlistedAt] = FieldValue.serverTimestamp();
      final String trimmedRemarks = (remarks ?? '').trim();
      if (trimmedRemarks.isNotEmpty) {
        patch[IdeaModel.fieldShortlistRemarks] = trimmedRemarks;
      }
    }

    await _db.collection(FirestoreUtils.hkzIdeas).doc(id).update(patch);
  }
}
