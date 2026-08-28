import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return EventPaymentsSection(
      kind: EventKind.ideathon,
      entries: _entries,
      metrics: _metrics,
      embedded: widget.embedded,
    );
  }
}
