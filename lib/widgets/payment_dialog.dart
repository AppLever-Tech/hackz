import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:hackz/features/idea/models/idea_model.dart';
import '../models/attachment_model.dart';
import '../models/payment_model.dart';
import '../features/team/models/team_model.dart';
import '../features/user/models/user_model.dart';
import '../shared/feedback/feedback.dart';
import '../utils/attachment_service.dart';
import '../utils/firestore_utils.dart';
import '../screens/common/app_dialog_template.dart';
import 'attachment_pick_field.dart';
import 'loading/loading.dart';
import 'responsive/responsive_dialog_actions.dart';

/// Compact student payment submission (amount + screenshot required).
Future<bool?> showPaymentDialog({
  required BuildContext context,
  required UserModel currentUser,
  required IdeaModel idea,
  required TeamModel team,
}) {
  return showAppDialog<bool>(
    context: context,
    width: DialogWidthPreset.compact,
    child: _PaymentDialog(
      currentUser: currentUser,
      idea: idea,
      team: team,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.currentUser,
    required this.idea,
    required this.team,
  });

  final UserModel currentUser;
  final IdeaModel idea;
  final TeamModel team;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _txnController = TextEditingController();
  PlatformFile? _picked;
  bool _busy = false;
  String? _errorMessage;

  static const Duration _uploadTimeout = Duration(seconds: 120);
  static const Duration _firestoreTimeout = Duration(seconds: 45);

  @override
  void dispose() {
    _amountController.dispose();
    _txnController.dispose();
    super.dispose();
  }

  String _formatSubmitError(Object e) {
    if (e is FirebaseException) {
      return e.message?.trim().isNotEmpty == true ? e.message!.trim() : e.code;
    }
    if (e is TimeoutException) {
      return 'Request timed out. Check your network, Storage rules, and Firestore rules, then try again.';
    }
    return e.toString();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid amount.');
      return;
    }
    if (_picked?.bytes == null || (_picked!.bytes?.isEmpty ?? true)) {
      setState(() => _errorMessage = 'Screenshot is required.');
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Saving Payment',
        message: 'Uploading payment proof and updating records...',
        successMessage: 'Payment submitted',
        task: () async {
          var ext = (_picked!.extension ?? 'jpg').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          if (ext.isEmpty) ext = 'jpg';
          if (ext == 'jpg') ext = 'jpeg';
          final authUid = FirebaseAuth.instance.currentUser?.uid;
          if (authUid == null || authUid.isEmpty) {
            throw StateError('Not signed in.');
          }
          final paymentId = widget.idea.ideaId;
          HkzAsyncLoader.update(
            message: 'Uploading payment screenshot securely...',
          );
          final uploaded = await AttachmentService.uploadAttachments(
            entityType: AttachmentEntityType.payment,
            entityId: paymentId,
            orgId: widget.idea.orgId,
            departmentCode: widget.idea.problemDepartmentCode,
            uploadedBy: widget.currentUser.userId,
            files: <PlatformFile>[_picked!],
            fileType: 'payment',
          ).timeout(_uploadTimeout);
          final url = uploaded.first.downloadUrl;
          HkzAsyncLoader.update(message: 'Saving payment record...');
          final payment = PaymentModel(
            paymentId: paymentId,
            ideaId: widget.idea.ideaId,
            teamId: widget.team.teamId,
            problemId: widget.idea.problemId,
            problemNumber: widget.idea.problemNumber,
            orgId: widget.idea.orgId,
            departmentCode: widget.idea.problemDepartmentCode,
            amount: amount,
            paymentProofUrl: url,
            paidByStudentId: widget.currentUser.userId,
            uploadedByAuthUid: authUid,
            status: PaymentRecordStatus.pending,
            verifiedBy: '',
            verifiedAt: null,
            remarks: '',
            createdAt: DateTime.now(),
            transactionId: _txnController.text.trim().isEmpty ? null : _txnController.text.trim(),
          );
          await FirestoreUtils.saveStudentIdeaPayment(payment).timeout(_firestoreTimeout);
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      assert(() {
        debugPrint('PaymentDialog submit failed: $e\n$stackTrace');
        return true;
      }());
      if (!mounted) return;
      final message = _formatSubmitError(e);
      setState(() => _errorMessage = message);
      FeedbackService.showError(
        context,
        title: 'Payment submission failed',
        message: message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('Upload payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _txnController,
          decoration: const InputDecoration(
            labelText: 'Transaction ID (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        AttachmentSingleImagePickField(
          file: _picked,
          enabled: !_busy,
          onChanged: (f) => setState(() => _picked = f),
        ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 13, color: Color(0xFFB93838)),
          ),
        ],
        const SizedBox(height: 16),
        ResponsiveDialogActions(
          children: <Widget>[
            OutlinedButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }
}
