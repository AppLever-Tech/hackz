import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';
import 'package:hackz/features/attachment/utils/attachment_preview_utils.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import 'package:hackz/features/problems/models/problem_model.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'package:hackz/utils/firestore_utils.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Linked entity surfaced in the attachment workspace.
class AttachmentRelatedEntity {
  const AttachmentRelatedEntity({
    required this.entityType,
    required this.entityId,
    required this.headline,
    required this.detail,
  });

  final AttachmentEntityType entityType;
  final String entityId;
  final String headline;
  final String detail;

  bool get canOpenWorkspace =>
      entityId.trim().isNotEmpty &&
      entityType != AttachmentEntityType.organization &&
      entityType != AttachmentEntityType.feedback;
}

class AttachmentWorkspaceViewModel {
  const AttachmentWorkspaceViewModel({
    required this.attachment,
    required this.resolvedUrl,
    required this.uploaderName,
    required this.related,
  });

  final AttachmentModel attachment;
  final String resolvedUrl;
  final String uploaderName;
  final AttachmentRelatedEntity? related;

  String get typeLabel => AttachmentPreviewUtils.typeLabel(attachment.attachmentType);

  String get sizeLabel => AttachmentPreviewUtils.formatSize(attachment.sizeInBytes);

  String get mimeLabel {
    final mime = attachment.mimeType.trim();
    if (mime.isNotEmpty) return mime;
    return attachment.fileType.trim().isEmpty ? typeLabel : attachment.fileType;
  }
}

abstract final class AttachmentWorkspaceLoader {
  static Future<AttachmentWorkspaceViewModel> load(String attachmentId) async {
    final String id = attachmentId.trim();
    if (id.isEmpty) {
      throw ArgumentError('attachmentId must be non-empty');
    }

    final AttachmentModel? attachment = await AttachmentService.fetchById(id);
    if (attachment == null) {
      throw StateError('Attachment not found');
    }

    final FirebaseFirestore db = HackzFirebase.current.firestore;
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      FirestoreUtils.fetchUser(attachment.uploadedBy.trim()),
      _loadRelated(db, attachment),
      _resolveDownloadUrl(attachment),
    ]);

    final UserModel? uploader = results[0] as UserModel?;
    final AttachmentRelatedEntity? related = results[1] as AttachmentRelatedEntity?;
    final String resolvedUrl = results[2] as String;

    final String uploaderName = uploader == null
        ? (attachment.uploadedBy.trim().isEmpty ? '—' : attachment.uploadedBy.trim())
        : userDisplayName(uploader);

    return AttachmentWorkspaceViewModel(
      attachment: attachment,
      resolvedUrl: resolvedUrl,
      uploaderName: uploaderName,
      related: related,
    );
  }

  static Future<String> _resolveDownloadUrl(AttachmentModel attachment) async {
    final String path = attachment.storagePath.trim();
    if (path.isEmpty) return attachment.downloadUrl;
    if (attachment.entityType != AttachmentEntityType.feedback) {
      HackzFirebase.assertOrganisationStorage();
    }
    try {
      return await HackzFirebase.current.storage.ref(path).getDownloadURL();
    } catch (_) {
      return attachment.downloadUrl;
    }
  }

  static Future<AttachmentRelatedEntity?> _loadRelated(
    FirebaseFirestore db,
    AttachmentModel attachment,
  ) async {
    final String entityId = attachment.entityId.trim();
    if (entityId.isEmpty) return null;

    switch (attachment.entityType) {
      case AttachmentEntityType.idea:
        final DocumentSnapshot<Map<String, dynamic>> doc =
            await db.collection(FirestoreUtils.hkzIdeas).doc(entityId).get();
        if (!doc.exists || doc.data() == null) {
          return AttachmentRelatedEntity(
            entityType: AttachmentEntityType.idea,
            entityId: entityId,
            headline: entityId,
            detail: 'Linked idea',
          );
        }
        final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data()!);
        final String title =
            idea.ideaTitle.trim().isEmpty ? idea.problemNumber.trim() : idea.ideaTitle.trim();
        return AttachmentRelatedEntity(
          entityType: AttachmentEntityType.idea,
          entityId: idea.ideaId,
          headline: title.isEmpty ? entityId : title,
          detail: idea.problemTitle.trim().isEmpty ? 'Innovation idea' : idea.problemTitle.trim(),
        );
      case AttachmentEntityType.problem:
        final DocumentSnapshot<Map<String, dynamic>> doc =
            await db.collection(FirestoreUtils.hkzProblems).doc(entityId).get();
        if (!doc.exists || doc.data() == null) {
          return AttachmentRelatedEntity(
            entityType: AttachmentEntityType.problem,
            entityId: entityId,
            headline: entityId,
            detail: 'Linked problem',
          );
        }
        final ProblemModel problem = ProblemModel.fromMap(doc.id, doc.data()!);
        final String title = problem.title.trim().isEmpty ? problem.problemNumber : problem.title.trim();
        return AttachmentRelatedEntity(
          entityType: AttachmentEntityType.problem,
          entityId: problem.problemId,
          headline: title.isEmpty ? entityId : title,
          detail: problem.departmentDisplayName,
        );
      case AttachmentEntityType.payment:
        PaymentModel? payment = await _loadPayment(db, entityId);
        if (payment == null) {
          return AttachmentRelatedEntity(
            entityType: AttachmentEntityType.payment,
            entityId: entityId,
            headline: entityId,
            detail: 'Linked payment',
          );
        }
        String detail = '₹${payment.amount.toStringAsFixed(0)} · ${payment.status.value}';
        String headline = payment.paymentId;
        if (payment.ideaId.trim().isNotEmpty) {
          final DocumentSnapshot<Map<String, dynamic>> ideaDoc =
              await db.collection(FirestoreUtils.hkzIdeas).doc(payment.ideaId.trim()).get();
          if (ideaDoc.exists && ideaDoc.data() != null) {
            final IdeaModel idea = IdeaModel.fromMap(ideaDoc.id, ideaDoc.data()!);
            if (idea.ideaTitle.trim().isNotEmpty) {
              headline = idea.ideaTitle.trim();
            }
          }
        }
        return AttachmentRelatedEntity(
          entityType: AttachmentEntityType.payment,
          entityId: payment.paymentId,
          headline: headline,
          detail: detail,
        );
      case AttachmentEntityType.organization:
        return null;
      case AttachmentEntityType.feedback:
        return AttachmentRelatedEntity(
          entityType: AttachmentEntityType.feedback,
          entityId: entityId,
          headline: entityId,
          detail: 'Linked feedback',
        );
    }
  }

  static Future<PaymentModel?> _loadPayment(FirebaseFirestore db, String id) async {
    final DocumentSnapshot<Map<String, dynamic>> primary =
        await db.collection(FirestoreUtils.hkzPayments).doc(id).get();
    if (primary.exists && primary.data() != null) {
      return PaymentModel.fromMap(primary.id, primary.data()!);
    }
    final QuerySnapshot<Map<String, dynamic>> byIdea = await db
        .collection(FirestoreUtils.hkzPayments)
        .where('ideaId', isEqualTo: id)
        .limit(1)
        .get();
    if (byIdea.docs.isEmpty) return null;
    return PaymentModel.fromMap(byIdea.docs.first.id, byIdea.docs.first.data());
  }
}
