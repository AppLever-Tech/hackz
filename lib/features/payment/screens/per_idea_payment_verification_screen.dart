import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/rich_tabs.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_async_loader.dart';
import '../../../features/events/models/event_payment_entry.dart';
import '../../../features/user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';
import '../../attachment/models/attachment_model.dart';
import '../../idea/models/idea_model.dart';
import '../models/payment_model.dart';
import '../services/per_idea_payment_verification_service.dart';
import '../widgets/payment_entries_view.dart';

/// Organisation-wide PER_IDEA payment verification for Hackz org admins.
class PerIdeaPaymentVerificationScreen extends StatefulWidget {
  const PerIdeaPaymentVerificationScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<PerIdeaPaymentVerificationScreen> createState() => _PerIdeaPaymentVerificationScreenState();
}

class _PerIdeaPaymentVerificationScreenState extends State<PerIdeaPaymentVerificationScreen> {
  late Future<_PaymentData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<_PaymentData> _load() async {
    final QuerySnapshot<Map<String, dynamic>> paymentSnap = await HackzFirebase.current.firestore
        .collection(FirestoreUtils.hkzPayments)
        .where('orgId', isEqualTo: widget.user.orgId)
        .get();
    final List<PaymentModel> payments = paymentSnap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => PaymentModel.fromMap(doc.id, doc.data()))
        .toList(growable: false);

    final QuerySnapshot<Map<String, dynamic>> teamSnap = await HackzFirebase.current.firestore
        .collection(FirestoreUtils.hkzTeams)
        .where('orgId', isEqualTo: widget.user.orgId)
        .get();
    final Map<String, String> teamNameById = <String, String>{
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in teamSnap.docs)
        doc.id: ((doc.data()['teamName'] as String?) ?? '').trim(),
    };

    final Set<String> ideaIds =
        payments.map((PaymentModel p) => p.ideaId.trim()).where((String id) => id.isNotEmpty).toSet();
    final Map<String, String> ideaTitleById = <String, String>{};
    if (ideaIds.isNotEmpty) {
      final QuerySnapshot<Map<String, dynamic>> ideaSnap = await HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzIdeas)
          .where('orgId', isEqualTo: widget.user.orgId)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in ideaSnap.docs) {
        if (!ideaIds.contains(doc.id)) continue;
        final IdeaModel idea = IdeaModel.fromMap(doc.id, doc.data());
        final String title = idea.ideaTitle.trim();
        ideaTitleById[doc.id] =
            title.isNotEmpty ? title : (idea.problemNumber.trim().isNotEmpty ? idea.problemNumber.trim() : doc.id);
      }
    }

    final Set<String> paymentIds = payments.map((PaymentModel p) => p.paymentId).toSet();
    final Map<String, int> attachmentCountByPaymentId = <String, int>{};
    if (paymentIds.isNotEmpty) {
      final QuerySnapshot<Map<String, dynamic>> attachmentSnap = await HackzFirebase.current.firestore
          .collection(FirestoreUtils.hkzAttachments)
          .where('orgId', isEqualTo: widget.user.orgId)
          .where('isActive', isEqualTo: true)
          .get();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in attachmentSnap.docs) {
        final AttachmentModel attachment = AttachmentModel.fromMap(doc.id, doc.data());
        if (attachment.entityType != AttachmentEntityType.payment) continue;
        if (!paymentIds.contains(attachment.entityId)) continue;
        attachmentCountByPaymentId[attachment.entityId] =
            (attachmentCountByPaymentId[attachment.entityId] ?? 0) + 1;
      }
    }

    return _PaymentData(
      payments: payments,
      teamNameById: teamNameById,
      ideaTitleById: ideaTitleById,
      attachmentCountByPaymentId: attachmentCountByPaymentId,
    );
  }

  List<EventPaymentEntry> _entries(List<PaymentModel> items, _PaymentData data) {
    return items
        .map(
          (PaymentModel p) {
            final bool pending = p.status == PaymentRecordStatus.pending;
            return EventPaymentEntry(
              entryId: p.ideaId,
              entryTitle: data.ideaTitleById[p.ideaId] ?? p.problemNumber,
              teamId: p.teamId,
              teamName: data.teamNameById[p.teamId] ?? p.teamId,
              status: p.status,
              payment: p,
              proofCount: _proofCount(p, data),
              canConfirm: pending,
              canMarkException: pending,
            );
          },
        )
        .toList(growable: false);
  }

  int _proofCount(PaymentModel payment, _PaymentData data) {
    final int count = data.attachmentCountByPaymentId[payment.paymentId] ?? 0;
    if (count > 0) return count;
    return payment.paymentProofUrl.trim().isNotEmpty ? 1 : 0;
  }

  Future<void> _verify(EventPaymentEntry row) async {
    final PaymentModel? payment = row.payment;
    if (payment == null) return;
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Approving payment',
        message: 'Updating payment status…',
        successMessage: 'Payment verified',
        task: () => PerIdeaPaymentVerificationService.verify(payment: payment, actor: widget.user),
      );
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to verify', message: '$e');
    }
  }

  Future<void> _reject(EventPaymentEntry row) async {
    final PaymentModel? payment = row.payment;
    if (payment == null) return;
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Rejecting payment',
        message: 'Updating payment status…',
        successMessage: 'Payment marked as exception',
        task: () => PerIdeaPaymentVerificationService.reject(payment: payment, actor: widget.user),
      );
      if (!mounted) return;
      _reload();
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to reject', message: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PaymentData>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<_PaymentData> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HkzProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load payments: ${snapshot.error}');
        }
        final _PaymentData data = snapshot.data!;
        final List<PaymentModel> pending = data.payments
            .where((PaymentModel p) => p.status == PaymentRecordStatus.pending)
            .toList(growable: false)
          ..sort((PaymentModel a, PaymentModel b) => b.createdAt.compareTo(a.createdAt));
        final List<PaymentModel> verified = data.payments
            .where((PaymentModel p) => p.status == PaymentRecordStatus.verified)
            .toList(growable: false)
          ..sort((PaymentModel a, PaymentModel b) => b.createdAt.compareTo(a.createdAt));
        final List<PaymentModel> rejected = data.payments
            .where((PaymentModel p) => p.status == PaymentRecordStatus.rejected)
            .toList(growable: false)
          ..sort((PaymentModel a, PaymentModel b) => b.createdAt.compareTo(a.createdAt));

        Widget list(List<PaymentModel> items, {required String emptyTitle}) {
          return PaymentEntriesView(
            entries: _entries(items, data),
            emptyTitle: emptyTitle,
            emptyMessage: 'Payments in this status will appear here.',
            onConfirm: _verify,
            onMarkException: _reject,
            confirmActionLabel: 'Approve',
            exceptionActionLabel: 'Reject',
            centeredTableHeaders: true,
          );
        }

        return RichTabs(
          spacingAfterBar: 10,
          tabs: <RichTabItem>[
            RichTabItem('Pending', icon: AppIcons.clock, count: pending.isEmpty ? null : pending.length, prominentCount: true),
            RichTabItem('Verified', icon: AppIcons.workflowApproved, count: verified.isEmpty ? null : verified.length, prominentCount: true),
            RichTabItem('Rejected', icon: AppIcons.workflowRejected, count: rejected.isEmpty ? null : rejected.length, prominentCount: true),
          ],
          children: <Widget>[
            list(pending, emptyTitle: 'No pending payments'),
            list(verified, emptyTitle: 'No verified payments'),
            list(rejected, emptyTitle: 'No rejected payments'),
          ],
        );
      },
    );
  }
}

class _PaymentData {
  const _PaymentData({
    required this.payments,
    required this.teamNameById,
    required this.ideaTitleById,
    required this.attachmentCountByPaymentId,
  });

  final List<PaymentModel> payments;
  final Map<String, String> teamNameById;
  final Map<String, String> ideaTitleById;
  final Map<String, int> attachmentCountByPaymentId;
}
