import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/data_view/data_table_column.dart';
import '../../../core/ui/data_view/data_table_view.dart';
import '../../../core/ui/inputs/filter_pill.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../../payment/models/payment_model.dart';
import '../../payment/services/department_payments_service.dart';
import '../../payment/services/payment_finance_helpers.dart';
import '../../payment/widgets/payment_metrics_row.dart';
import '../../payment/widgets/payment_table_columns.dart';
import '../models/event_kind.dart';
import '../models/event_payment_entry.dart';

enum EventPaymentFilter { all, confirmed, pending, exception }

/// Event-generic Payments workspace (Ideathon today; Hackathon later).
class EventPaymentsSection extends StatefulWidget {
  const EventPaymentsSection({
    super.key,
    required this.kind,
    required this.entries,
    required this.metrics,
    this.embedded = false,
  });

  final EventKind kind;
  final List<EventPaymentEntry> entries;
  final EventPaymentMetrics metrics;
  final bool embedded;

  @override
  State<EventPaymentsSection> createState() => _EventPaymentsSectionState();
}

class _EventPaymentsSectionState extends State<EventPaymentsSection> {
  EventPaymentFilter _filter = EventPaymentFilter.all;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventPaymentEntry> get _filtered {
    final String q = _searchController.text.trim().toLowerCase();
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

  DepartmentPaymentsSummary get _summary {
    double total = 0;
    double confirmed = 0;
    double pending = 0;
    double rejected = 0;
    for (final EventPaymentEntry row in widget.entries) {
      final double amount = row.payment?.amount ?? 0;
      total += amount;
      switch (row.status) {
        case PaymentRecordStatus.verified:
          confirmed += amount;
        case PaymentRecordStatus.pending:
          pending += amount;
        case PaymentRecordStatus.rejected:
          rejected += amount;
      }
    }
    return DepartmentPaymentsSummary(
      totalCollection: total,
      verifiedCount: widget.metrics.confirmed,
      verifiedAmount: confirmed,
      pendingCount: widget.metrics.pending,
      pendingAmount: pending,
      rejectedCount: widget.metrics.exceptions,
      rejectedAmount: rejected,
    );
  }

  String _statusLabel(PaymentRecordStatus status) {
    return switch (status) {
      PaymentRecordStatus.verified => 'Confirmed',
      PaymentRecordStatus.pending => 'Pending',
      PaymentRecordStatus.rejected => 'Exception',
    };
  }

  String _amountLabel(EventPaymentEntry row) {
    if (row.payment == null) return '—';
    return PaymentFinanceHelpers.formatCurrency(row.payment!.amount);
  }

  String _dateLabel(EventPaymentEntry row) {
    final DateTime? at = row.payment?.createdAt;
    if (at == null) return '—';
    return formatDateTime(at);
  }

  void _openEntry(BuildContext context, EventPaymentEntry row) {
    WorkspaceNavigator.openIdea(context, row.entryId);
  }

  void _openTeam(BuildContext context, EventPaymentEntry row) {
    if (row.teamId.trim().isEmpty) return;
    WorkspaceNavigator.openTeam(context, row.teamId);
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
    final EventPaymentMetrics metrics = widget.metrics;
    final String ideasLabel = widget.kind.entriesLabel.toLowerCase();

    final Widget toolbar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PaymentMetricsRow(
          summary: _summary,
          spacing: mobile ? 8 : 10,
          runSpacing: mobile ? 8 : 10,
          pendingLabel: 'Pending payments',
          collectionSubtitle: '${metrics.total} $ideasLabel',
          verifiedSubtitle: '${metrics.confirmed} confirmed',
          pendingSubtitle: '${metrics.pending} pending',
          rejectedSubtitle: '${metrics.exceptions} exception',
          forceChipGrid: true,
        ),
        SizedBox(height: mobile ? 8 : 10),
        ResponsiveSearchFilterBar(
          searchController: _searchController,
          searchHint: 'Search ${widget.kind.payableItemLabel.toLowerCase()}, team…',
          filtersExpanded: _showFilters,
          onToggleFilters: () => setState(() => _showFilters = !_showFilters),
          filterLabel: _showFilters ? 'Hide Filters' : 'Show Filters',
          iconOnlyFilterOnMobile: false,
          searchTextStyle: HackzInputDecoration.compactFieldTextStyle,
          searchDecoration: HackzInputDecoration.decorate(
            hintText: 'Search ${widget.kind.payableItemLabel.toLowerCase()}, team…',
            compact: true,
            prefixIcon: const Icon(AppIcons.search, size: 18),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilterPill(
                  selected: _filter == EventPaymentFilter.all,
                  icon: AppIcons.payments,
                  label: 'All',
                  count: metrics.total,
                  onTap: () => setState(() => _filter = EventPaymentFilter.all),
                ),
                FilterPill(
                  selected: _filter == EventPaymentFilter.confirmed,
                  icon: AppIcons.workflowApproved,
                  label: 'Confirmed',
                  count: metrics.confirmed,
                  foregroundColor: const Color(0xFF047857),
                  onTap: () => setState(() => _filter = EventPaymentFilter.confirmed),
                ),
                FilterPill(
                  selected: _filter == EventPaymentFilter.pending,
                  icon: AppIcons.clock,
                  label: 'Pending',
                  count: metrics.pending,
                  foregroundColor: const Color(0xFFEA580C),
                  onTap: () => setState(() => _filter = EventPaymentFilter.pending),
                ),
                FilterPill(
                  selected: _filter == EventPaymentFilter.exception,
                  icon: AppIcons.error,
                  label: 'Exception',
                  count: metrics.exceptions,
                  foregroundColor: const Color(0xFFB91C1C),
                  onTap: () => setState(() => _filter = EventPaymentFilter.exception),
                ),
              ],
            ),
          ),
          crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
        SizedBox(height: mobile ? 8 : 10),
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
          label: widget.kind.payableItemLabel,
          flex: 4,
          minWidth: 180,
          gapAfter: 12,
          cell: (BuildContext context, EventPaymentEntry row) => _pillCell(_ideaPill(context, row)),
        ),
        DataTableColumn<EventPaymentEntry>(
          label: 'Team',
          flex: 3,
          minWidth: 140,
          gapAfter: 12,
          cell: (BuildContext context, EventPaymentEntry row) => _pillCell(_teamPill(context, row)),
        ),
        DataTableColumn<EventPaymentEntry>(
          label: 'Payment Date',
          flex: 2,
          minWidth: 148,
          gapAfter: 12,
          cell: (_, EventPaymentEntry row) => Text(
            _dateLabel(row),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ),
        DataTableColumn<EventPaymentEntry>(
          label: 'Status',
          flex: 2,
          minWidth: 130,
          gapAfter: 12,
          cell: (BuildContext context, EventPaymentEntry row) => _pillCell(_statusPill(context, row)),
        ),
        DataTableColumn<EventPaymentEntry>(
          label: 'Amount',
          flex: 2,
          minWidth: 100,
          align: Alignment.centerRight,
          cell: (_, EventPaymentEntry row) => Align(
            alignment: Alignment.centerRight,
            child: Text(_amountLabel(row), style: PaymentListStyles.amount),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _ideaPill(context, row)),
                const SizedBox(width: 8),
                Text(_amountLabel(row), style: PaymentListStyles.amount),
              ],
            ),
            const SizedBox(height: 8),
            _teamPill(context, row),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _dateLabel(row),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ),
                _statusPill(context, row),
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) => card(rows[i]),
    );
  }

  Widget _pillCell(Widget child) {
    return Align(
      alignment: Alignment.centerLeft,
      child: UnconstrainedBox(
        alignment: Alignment.centerLeft,
        constrainedAxis: Axis.vertical,
        child: child,
      ),
    );
  }

  Widget _ideaPill(BuildContext context, EventPaymentEntry row) {
    final String label = row.entryTitle.trim().isEmpty ? row.entryId : row.entryTitle;
    if (row.entryId.trim().isEmpty) {
      return EntityCardPills.meta(label, icon: AppIcons.ideas);
    }
    return EntityCardPills.workspace(
      label,
      ContextPillSemantic.idea,
      () => _openEntry(context, row),
      icon: AppIcons.ideas,
    );
  }

  Widget _teamPill(BuildContext context, EventPaymentEntry row) {
    final String label = row.teamName.trim().isEmpty ? '—' : row.teamName;
    if (row.teamId.trim().isEmpty) {
      return EntityCardPills.meta(label, icon: AppIcons.teams);
    }
    return EntityCardPills.workspace(
      label,
      ContextPillSemantic.team,
      () => _openTeam(context, row),
      icon: AppIcons.teams,
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
}
