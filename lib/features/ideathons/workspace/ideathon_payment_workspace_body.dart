import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_alert_dialog.dart';
import '../../../core/responsive/responsive_dialog.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../events/models/event_kind.dart';
import '../../events/models/event_payment_entry.dart';
import '../../events/widgets/event_payments_section.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_payment_service.dart';

class IdeathonPaymentWorkspaceBody extends StatefulWidget {
  const IdeathonPaymentWorkspaceBody({
    super.key,
    required this.vm,
    this.actor,
    this.embedded = false,
  });

  final IdeathonPaymentWorkspaceViewModel vm;
  final UserModel? actor;

  /// When true, used inside Event Details (bounded height, no extra chrome).
  final bool embedded;

  @override
  State<IdeathonPaymentWorkspaceBody> createState() => _IdeathonPaymentWorkspaceBodyState();
}

class _IdeathonPaymentWorkspaceBodyState extends State<IdeathonPaymentWorkspaceBody> {
  late IdeathonPaymentWorkspaceViewModel _vm;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _vm = widget.vm;
  }

  @override
  void didUpdateWidget(covariant IdeathonPaymentWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm != widget.vm) _vm = widget.vm;
  }

  List<EventPaymentEntry> get _entries => _vm.rows
      .map(
        (IdeathonPaymentRow row) => EventPaymentEntry(
          entryId: row.ideaId,
          entryTitle: row.ideaTitle,
          teamId: row.teamId,
          teamName: row.teamName,
          payerId: row.payerId,
          payerName: row.payerName,
          payment: row.payment,
          status: row.displayPaymentStatus,
          canConfirm: row.canVerify,
          canMarkException: row.canReject,
        ),
      )
      .toList(growable: false);

  EventPaymentMetrics get _metrics => EventPaymentMetrics(
        total: _vm.metrics.totalIdeas,
        confirmed: _vm.metrics.paymentCompleted,
        pending: _vm.metrics.paymentPending,
        exceptions: _vm.metrics.paymentException,
      );

  IdeathonPaymentRow? _rowFor(EventPaymentEntry entry) {
    for (final IdeathonPaymentRow row in _vm.rows) {
      if (row.ideaId == entry.entryId) return row;
    }
    return null;
  }

  Future<void> _reload() async {
    final IdeathonPaymentWorkspaceViewModel next =
        await IdeathonPaymentService.load(_vm.ideathon.ideathonId);
    if (!mounted) return;
    setState(() => _vm = next);
  }

  Future<void> _confirm(EventPaymentEntry entry) async {
    final UserModel? actor = widget.actor;
    final IdeathonPaymentRow? row = _rowFor(entry);
    if (actor == null || row == null) {
      FeedbackService.showError(context, title: 'Unable to confirm', message: 'Coordinator session required.');
      return;
    }
    setState(() => _busy = true);
    try {
      await IdeathonPaymentService.verifyRow(row: row, coordinator: actor);
      await _reload();
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Payment confirmed',
        message: 'This idea is eligible for the event.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Confirm failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markException(EventPaymentEntry entry) async {
    final UserModel? actor = widget.actor;
    final IdeathonPaymentRow? row = _rowFor(entry);
    if (actor == null || row == null) {
      FeedbackService.showError(context, title: 'Unable to reject', message: 'Coordinator session required.');
      return;
    }
    final TextEditingController remarks = TextEditingController(text: row.payment?.remarks ?? '');
    final String? confirmed = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        return ResponsiveAlertDialog(
          title: const Text('Payment exception'),
          widthPreset: DialogWidthPreset.compact,
          content: TextField(
            controller: remarks,
            maxLines: 3,
            style: HackzInputDecoration.compactFieldTextStyle,
            decoration: HackzInputDecoration.decorate(
              hintText: 'Remarks',
              compact: true,
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, remarks.text.trim()),
              child: const Text('Mark exception'),
            ),
          ],
        );
      },
    );
    remarks.dispose();
    if (confirmed == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await IdeathonPaymentService.rejectRow(
        row: row,
        coordinator: actor,
        remarks: confirmed.isEmpty ? null : confirmed,
      );
      await _reload();
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Payment exception recorded',
        message: 'Participation remains payment pending.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Reject failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        EventPaymentsSection(
          kind: EventKind.ideathon,
          entries: _entries,
          metrics: _metrics,
          canManage: widget.actor != null,
          busy: _busy,
          embedded: widget.embedded,
          onConfirm: _confirm,
          onMarkException: _markException,
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66FFFFFF),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
