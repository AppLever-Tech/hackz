import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/data_view/data_table_column.dart';
import '../../../core/ui/data_view/data_table_view.dart';
import '../../../core/ui/inputs/filter_pill.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../payment/models/payment_model.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../models/event_kind.dart';
import '../models/event_payment_entry.dart';
import 'event_meta_chip.dart';

enum EventPaymentFilter { all, confirmed, pending, exception }

/// Event-generic Payments workspace (Ideathon today; Hackathon later).
class EventPaymentsSection extends StatefulWidget {
  const EventPaymentsSection({
    super.key,
    required this.kind,
    required this.entries,
    required this.metrics,
    this.canManage = false,
    this.busy = false,
    this.embedded = false,
    this.onConfirm,
    this.onMarkException,
  });

  final EventKind kind;
  final List<EventPaymentEntry> entries;
  final EventPaymentMetrics metrics;
  final bool canManage;
  final bool busy;
  final bool embedded;
  final ValueChanged<EventPaymentEntry>? onConfirm;
  final ValueChanged<EventPaymentEntry>? onMarkException;

  @override
  State<EventPaymentsSection> createState() => _EventPaymentsSectionState();
}

class _EventPaymentsSectionState extends State<EventPaymentsSection> {
  String _search = '';
  EventPaymentFilter _filter = EventPaymentFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventPaymentEntry> get _filtered {
    final String q = _search.trim().toLowerCase();
    return widget.entries.where((EventPaymentEntry row) {
      switch (_filter) {
        case EventPaymentFilter.confirmed:
          if (row.status != PaymentRecordStatus.verified) return false;
        case EventPaymentFilter.pending:
          if (row.status != PaymentRecordStatus.pending) return false;
        case EventPaymentFilter.exception:
          if (row.status != PaymentRecordStatus.rejected) return false;
        case EventPaymentFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      final String hay = <String>[
        row.entryTitle,
        row.teamName,
        row.payerName,
        row.payment?.remarks ?? '',
        row.payment?.transactionId ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList(growable: false);
  }

  String _statusLabel(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.verified => 'Confirmed',
      PaymentRecordStatus.pending => 'Pending',
      PaymentRecordStatus.rejected => 'Exception',
    };
  }

  void _openEntry(BuildContext context, EventPaymentEntry row) {
    WorkspaceNavigator.openIdea(context, row.entryId);
  }

  void _openPayment(BuildContext context, EventPaymentEntry row) {
    final String? id = row.paymentId;
    if (id == null) {
      _openEntry(context, row);
      return;
    }
    WorkspaceNavigator.openPayment(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final List<EventPaymentEntry> rows = _filtered;
    final EdgeInsets pad = widget.embedded
        ? const EdgeInsets.fromLTRB(4, 4, 4, 20)
        : EdgeInsets.fromLTRB(mobile ? 12 : 16, 8, mobile ? 12 : 16, 28);

    final Widget toolbar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Payments',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            EventMetaChip(
              icon: AppIcons.ideas,
              label: '${widget.metrics.total} ${widget.kind.entriesLabel}',
              color: const Color(0xFF4F46E5),
            ),
            EventMetaChip(
              icon: AppIcons.workflowApproved,
              label: '${widget.metrics.confirmed} Confirmed',
              color: const Color(0xFF047857),
            ),
            EventMetaChip(
              icon: AppIcons.clock,
              label: '${widget.metrics.pending} Pending',
              color: const Color(0xFFEA580C),
            ),
            EventMetaChip(
              icon: AppIcons.error,
              label: '${widget.metrics.exceptions} Exceptions',
              color: const Color(0xFFB91C1C),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (String v) => setState(() => _search = v),
          style: HackzInputDecoration.compactFieldTextStyle,
          decoration: HackzInputDecoration.decorate(
            hintText: 'Search ${widget.kind.payableItemLabel.toLowerCase()}, team…',
            compact: true,
            prefixIcon: const Icon(AppIcons.search, size: 18),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilterPill(
              selected: _filter == EventPaymentFilter.all,
              icon: AppIcons.payments,
              label: 'All',
              count: widget.metrics.total,
              onTap: () => setState(() => _filter = EventPaymentFilter.all),
            ),
            FilterPill(
              selected: _filter == EventPaymentFilter.confirmed,
              icon: AppIcons.workflowApproved,
              label: 'Confirmed',
              count: widget.metrics.confirmed,
              foregroundColor: const Color(0xFF047857),
              onTap: () => setState(() => _filter = EventPaymentFilter.confirmed),
            ),
            FilterPill(
              selected: _filter == EventPaymentFilter.pending,
              icon: AppIcons.clock,
              label: 'Pending',
              count: widget.metrics.pending,
              foregroundColor: const Color(0xFFEA580C),
              onTap: () => setState(() => _filter = EventPaymentFilter.pending),
            ),
            FilterPill(
              selected: _filter == EventPaymentFilter.exception,
              icon: AppIcons.error,
              label: 'Exception',
              count: widget.metrics.exceptions,
              foregroundColor: const Color(0xFFB91C1C),
              onTap: () => setState(() => _filter = EventPaymentFilter.exception),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );

    final Widget body = rows.isEmpty
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: kDashboardCardDecoration,
            child: Text(
              widget.entries.isEmpty
                  ? 'No ${widget.kind.payableItemLabel.toLowerCase()} payments for this event yet.'
                  : 'No payments match your filters.',
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          )
        : (widget.embedded && !mobile)
            ? _table(context, rows)
            : _cards(context, rows, scrollable: widget.embedded);

    if (widget.embedded) {
      return Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            toolbar,
            Expanded(child: body),
          ],
        ),
      );
    }

    return ListView(
      padding: pad,
      children: <Widget>[
        toolbar,
        body,
      ],
    );
  }

  Widget _table(BuildContext context, List<EventPaymentEntry> rows) {
    return DataTableView<EventPaymentEntry>(
      items: rows,
      rowMinHeight: 56,
      columns: <DataTableColumn<EventPaymentEntry>>[
        DataTableColumn<EventPaymentEntry>(
          label: '${widget.kind.payableItemLabel} / Team',
          flex: 5,
          minWidth: 220,
          gapAfter: 12,
          cell: (BuildContext context, EventPaymentEntry row) => Align(
            alignment: Alignment.centerLeft,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              constrainedAxis: Axis.vertical,
              child: _entryTeamPills(context, row),
            ),
          ),
        ),
        DataTableColumn<EventPaymentEntry>(
          label: 'Payment Status',
          flex: 2,
          minWidth: 130,
          gapAfter: 12,
          cell: (BuildContext context, EventPaymentEntry row) => Align(
            alignment: Alignment.centerLeft,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              constrainedAxis: Axis.vertical,
              child: _statusPill(context, row),
            ),
          ),
        ),
        DataTableColumn<EventPaymentEntry>(
          label: 'Action',
          flex: 3,
          minWidth: 168,
          cell: (BuildContext context, EventPaymentEntry row) => Align(
            alignment: Alignment.centerLeft,
            child: UnconstrainedBox(
              alignment: Alignment.centerLeft,
              constrainedAxis: Axis.vertical,
              child: _actions(context, row),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cards(BuildContext context, List<EventPaymentEntry> rows, {required bool scrollable}) {
    Widget card(EventPaymentEntry row) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: kDashboardCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _entryTeamPills(context, row),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _statusPill(context, row),
                _actions(context, row),
              ],
            ),
          ],
        ),
      );
    }

    if (!scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            card(rows[i]),
          ],
        ],
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int i) => card(rows[i]),
    );
  }

  Widget _entryTeamPills(BuildContext context, EventPaymentEntry row) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        ContextPill(
          label: row.entryTitle.trim().isEmpty ? row.entryId : row.entryTitle,
          semantic: ContextPillSemantic.idea,
          onTap: () => _openEntry(context, row),
          compact: true,
          fitContent: true,
          expandWidth: false,
          allowHoverScale: false,
        ),
        ContextPill(
          label: row.teamName.trim().isEmpty ? '—' : row.teamName,
          semantic: ContextPillSemantic.team,
          onTap: row.teamId.trim().isEmpty ? () {} : () => WorkspaceNavigator.openTeam(context, row.teamId),
          enabled: row.teamId.trim().isNotEmpty,
          compact: true,
          fitContent: true,
          expandWidth: false,
          allowHoverScale: false,
        ),
      ],
    );
  }

  Widget _statusPill(BuildContext context, EventPaymentEntry row) {
    return ContextPill(
      label: _statusLabel(row.status),
      semantic: ContextPillSemantic.payment,
      onTap: () => _openPayment(context, row),
      enabled: row.paymentId != null,
      compact: true,
      fitContent: true,
      expandWidth: false,
      allowHoverScale: false,
    );
  }

  Widget _actions(BuildContext context, EventPaymentEntry row) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        ProblemWorkflowActionPill(
          label: 'View',
          icon: AppIcons.preview,
          semantic: ProblemWorkflowPillSemantic.primary,
          onTap: () => _openPayment(context, row),
        ),
        if (widget.canManage && row.canConfirm && widget.onConfirm != null)
          ProblemWorkflowActionPill(
            label: 'Confirm',
            icon: AppIcons.workflowApproved,
            semantic: ProblemWorkflowPillSemantic.filledBrand,
            enabled: !widget.busy,
            onTap: () => widget.onConfirm!(row),
          ),
        if (widget.canManage && row.canMarkException && widget.onMarkException != null)
          ProblemWorkflowActionPill(
            label: 'Exception',
            icon: AppIcons.workflowRejected,
            semantic: ProblemWorkflowPillSemantic.closed,
            enabled: !widget.busy,
            onTap: () => widget.onMarkException!(row),
          ),
      ],
    );
  }
}
