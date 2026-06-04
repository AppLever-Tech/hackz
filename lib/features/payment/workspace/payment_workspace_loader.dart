import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/organization/models/department_model.dart';
import 'package:hackz/features/team/models/team_model.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/models/attachment_model.dart';
import 'package:hackz/utils/common_helpers.dart';
import 'package:hackz/utils/firestore_utils.dart';
import 'package:hackz/workspace/core/workspace_attachment_counts.dart';

import '../models/payment_model.dart';
import '../services/payment_finance_helpers.dart';

class PaymentWorkspaceViewModel {
  const PaymentWorkspaceViewModel({
    required this.payment,
    required this.ideaTitle,
    required this.teamName,
    required this.departmentLabel,
    required this.payerName,
    required this.verifierName,
    required this.proofAttachmentCounts,
    required this.proofAttachments,
    required this.hasLegacyProofUrl,
    required this.hasProof,
    required this.needsAttention,
  });

  final PaymentModel payment;
  final String ideaTitle;
  final String teamName;
  final String departmentLabel;
  final String payerName;
  final String verifierName;
  final WorkspaceAttachmentCounts proofAttachmentCounts;
  final List<AttachmentModel> proofAttachments;
  final bool hasLegacyProofUrl;
  final bool hasProof;
  final bool needsAttention;
}

abstract final class PaymentWorkspaceLoader {
  static Future<PaymentWorkspaceViewModel> load(String paymentId) async {
    final String id = paymentId.trim();
    if (id.isEmpty) {
      throw ArgumentError('paymentId must be non-empty');
    }

    final FirebaseFirestore db = FirebaseFirestore.instance;
    PaymentModel? payment = await _loadPayment(db, id);
    if (payment == null) {
      throw StateError('Payment not found');
    }

    final String orgId = payment.orgId.trim();
    final String ideaId = payment.ideaId.trim();

    final List<dynamic> secondary = await Future.wait<dynamic>(<Future<dynamic>>[
      ideaId.isEmpty
          ? Future<IdeaModel?>.value(null)
          : db.collection(FirestoreUtils.hkzIdeas).doc(ideaId).get().then((doc) {
              if (!doc.exists || doc.data() == null) return null;
              return IdeaModel.fromMap(doc.id, doc.data()!);
            }),
      payment.teamId.trim().isEmpty
          ? Future<TeamModel?>.value(null)
          : db.collection(FirestoreUtils.hkzTeams).doc(payment.teamId.trim()).get().then((doc) {
              if (!doc.exists || doc.data() == null) return null;
              return TeamModel.fromMap(doc.id, doc.data()!);
            }),
      FirestoreUtils.fetchUser(payment.paidByStudentId.trim()),
      payment.verifiedBy.trim().isEmpty
          ? Future<UserModel?>.value(null)
          : FirestoreUtils.fetchUser(payment.verifiedBy.trim()),
      orgId.isEmpty
          ? Future<QuerySnapshot<Map<String, dynamic>>>.value(
              await db.collection(FirestoreUtils.hkzAttachments).limit(0).get(),
            )
          : db
              .collection(FirestoreUtils.hkzAttachments)
              .where('orgId', isEqualTo: orgId)
              .where('isActive', isEqualTo: true)
              .limit(200)
              .get(),
    ]);

    final IdeaModel? idea = secondary[0] as IdeaModel?;
    final TeamModel? team = secondary[1] as TeamModel?;
    final UserModel? payer = secondary[2] as UserModel?;
    final UserModel? verifier = secondary[3] as UserModel?;
    final QuerySnapshot<Map<String, dynamic>> attachmentSnap =
        secondary[4] as QuerySnapshot<Map<String, dynamic>>;

    final String paymentKey = payment.paymentId.trim();
    final List<AttachmentModel> proofAttachments = attachmentSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => AttachmentModel.fromMap(d.id, d.data()))
        .where(
          (AttachmentModel a) =>
              a.entityType == AttachmentEntityType.payment &&
              (a.entityId == paymentKey || a.entityId == ideaId),
        )
        .toList(growable: false)
      ..sort((AttachmentModel a, AttachmentModel b) => b.createdAt.compareTo(a.createdAt));
    final WorkspaceAttachmentCounts proofAttachmentCounts =
        WorkspaceAttachmentCounts.fromModels(proofAttachments);

    final bool hasLegacyProofUrl = payment.paymentProofUrl.trim().isNotEmpty;
    final bool hasProof = hasLegacyProofUrl || !proofAttachmentCounts.isEmpty;
    final DepartmentModel? dept = DepartmentModel.byCode(payment.departmentCode);

    final String ideaTitle = idea?.ideaTitle.trim().isNotEmpty == true
        ? idea!.ideaTitle.trim()
        : (ideaId.isEmpty ? '—' : ideaId);
    final String teamName = team?.teamName.trim().isNotEmpty == true
        ? team!.teamName.trim()
        : (payment.teamId.trim().isEmpty ? '—' : payment.teamId.trim());
    final String payerName = payer == null
        ? (payment.paidByStudentId.trim().isEmpty ? '—' : payment.paidByStudentId.trim())
        : userDisplayName(payer);
    final String verifierName = verifier == null
        ? (payment.verifiedBy.trim().isEmpty ? '—' : payment.verifiedBy.trim())
        : userDisplayName(verifier);

    return PaymentWorkspaceViewModel(
      payment: payment,
      ideaTitle: ideaTitle,
      teamName: teamName,
      departmentLabel: dept?.name ?? payment.departmentCode,
      payerName: payerName,
      verifierName: verifierName,
      proofAttachmentCounts: proofAttachmentCounts,
      proofAttachments: proofAttachments,
      hasLegacyProofUrl: hasLegacyProofUrl,
      hasProof: hasProof,
      needsAttention: PaymentFinanceHelpers.needsAttention(payment, hasProof: hasProof),
    );
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
    final QueryDocumentSnapshot<Map<String, dynamic>> doc = byIdea.docs.first;
    return PaymentModel.fromMap(doc.id, doc.data());
  }
}
