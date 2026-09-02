import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';
import 'package:hackz/core/ui/dialog/app_dialog_template.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/core/ui/inputs/hackz_input_decoration.dart';
import 'package:hackz/core/responsive/responsive_dialog_actions.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';
import 'package:hackz/features/attachment/widgets/attachment_pick_field.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/ideathons/models/ideathon_model.dart';
import 'package:hackz/features/ideathons/services/ideathon_service.dart';
import 'package:hackz/features/ideathons/widgets/ideathon_event_select_field.dart';
import 'package:hackz/features/team/models/team_model.dart';
import 'package:hackz/features/team/services/team_service.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/core/ui/loading/loading.dart';
import 'package:hackz/utils/firestore_utils.dart';

import '../models/payment_model.dart';

/// Team Leader payment submission: amount, screenshot, and eligible event.
Future<bool?> showPaymentDialog({
  required BuildContext context,
  required UserModel currentUser,
  required IdeaModel idea,
  required TeamModel team,
  String initialEventId = '',
}) {
  return showAppDialog<bool>(
    context: context,
    width: DialogWidthPreset.standard,
    child: _PaymentDialog(
      currentUser: currentUser,
      idea: idea,
      team: team,
      initialEventId: initialEventId,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.currentUser,
    required this.idea,
    required this.team,
    this.initialEventId = '',
  });

  final UserModel currentUser;
  final IdeaModel idea;
  final TeamModel team;
  final String initialEventId;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _txnController = TextEditingController();
  PlatformFile? _picked;
  bool _busy = false;
  bool _loadingEvents = true;
  String? _errorMessage;
  String? _selectedEventId;
  List<IdeathonModel> _events = const <IdeathonModel>[];

  static const Duration _uploadTimeout = Duration(seconds: 120);
  static const Duration _firestoreTimeout = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _txnController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _loadingEvents = true);
    try {
      final List<IdeathonModel> open = await IdeathonService.listOpenForTeam(
        team: widget.team,
        problemId: widget.idea.problemId,
      );
      final PaymentModel? existing = await FirestoreUtils.getPaymentByIdeaId(widget.idea.ideaId);
      final String preferred = widget.initialEventId.trim().isNotEmpty
          ? widget.initialEventId.trim()
          : (existing?.ideathonId.trim() ?? '');
      String? selected;
      if (preferred.isNotEmpty && open.any((IdeathonModel e) => e.ideathonId.trim() == preferred)) {
        selected = preferred;
      } else if (open.length == 1) {
        selected = open.first.ideathonId;
      }
      if (!mounted) return;
      setState(() {
        _events = open;
        _selectedEventId = selected;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _loadingEvents = false);
    }
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
    final String eventId = (_selectedEventId ?? '').trim();
    if (eventId.isEmpty) {
      setState(() => _errorMessage = 'Select an eligible Ideathon event.');
      return;
    }
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
          final authUid = FirebaseAuth.instance.currentUser?.uid;
          if (authUid == null || authUid.isEmpty) {
            throw StateError('Not signed in.');
          }
          if (!TeamService.isActingTeamLeader(widget.currentUser, widget.team)) {
            throw TeamRuleException('Only the team leader can submit payment for this team.');
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
            ideathonId: eventId,
          );
          await IdeathonService.saveTeamLeaderEventPayment(
            payment: payment,
            eventId: eventId,
          ).timeout(_firestoreTimeout);
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
    final String ideaTitle =
        widget.idea.ideaTitle.trim().isEmpty ? widget.idea.ideaId : widget.idea.ideaTitle.trim();
    final String teamName = widget.team.teamName.trim().isEmpty ? 'Team' : widget.team.teamName.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF7C3AED), Color(0xFF0891B2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(AppIcons.payments, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Upload payment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select the Ideathon, then submit amount and proof.',
                    style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            ContextPill(
              label: ideaTitle,
              semantic: ContextPillSemantic.idea,
              onTap: () {},
              enabled: false,
              compact: true,
              fitContent: true,
            ),
            ContextPill(
              label: teamName,
              semantic: ContextPillSemantic.team,
              onTap: () {},
              enabled: false,
              compact: true,
              fitContent: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              IdeathonEventSelectField(
                events: _events,
                selectedEventId: _selectedEventId,
                enabled: !_busy,
                loading: _loadingEvents,
                onChanged: (String id) => setState(() {
                  _selectedEventId = id;
                  _errorMessage = null;
                }),
              ),
              if (!_loadingEvents && _events.isEmpty) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  'No Ideathon is open for this team and problem. Submission cutoff may have passed.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 14),
              HackzInputDecoration.labeledField(
                label: 'Amount',
                required: true,
                field: TextField(
                  controller: _amountController,
                  enabled: !_busy,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: HackzInputDecoration.fieldTextStyle,
                  decoration: HackzInputDecoration.decorate(
                    hintText: '0.00',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18, color: HackzInputDecoration.iconColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              HackzInputDecoration.labeledField(
                label: 'Transaction ID',
                field: TextField(
                  controller: _txnController,
                  enabled: !_busy,
                  style: HackzInputDecoration.fieldTextStyle,
                  decoration: HackzInputDecoration.decorate(hintText: 'Optional reference'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Payment screenshot', style: HackzInputDecoration.labelStyle),
              const SizedBox(height: 6),
              AttachmentSingleImagePickField(
                file: _picked,
                enabled: !_busy,
                onChanged: (f) => setState(() => _picked = f),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 13, color: HackzInputDecoration.errorColor),
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
              onPressed: _busy || _loadingEvents || _events.isEmpty ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }
}
