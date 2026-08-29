import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_filter_bar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/filters/hackz_filter_pane.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../payment/models/payment_model.dart';
import '../../payment/services/department_payments_service.dart';
import '../../payment/widgets/payment_entries_view.dart';
import '../../payment/widgets/payment_metrics_row.dart';
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

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final List<EventPaymentEntry> rows = _filtered;
    final EdgeInsets pad = widget.embedded
        ? const EdgeInsets.fromLTRB(4, 4, 4, 20)
        : EdgeInsets.fromLTRB(mobile ? 12 : 16, 8, mobile ? 12 : 16, 28);
    final EventPaymentMetrics metrics = widget.metrics;
    final String ideasLabel = widget.kind.entriesLabel.toLowerCase();
    final bool hasActiveFilters = _filter != EventPaymentFilter.all || _searchController.text.trim().isNotEmpty;

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
            child: HackzFilterPane(
              onClearAll: () => setState(() => _filter = EventPaymentFilter.all),
              sections: <Widget>[
                HackzFilterSection.chips(
                  icon: AppIcons.payments,
                  label: 'Status',
                  chips: <Widget>[
                    HackzFilterChips.choice(
                      icon: AppIcons.payments,
                      label: _countLabel('All', metrics.total),
                      selected: _filter == EventPaymentFilter.all,
                      onSelected: () => setState(() => _filter = EventPaymentFilter.all),
                    ),
                    HackzFilterChips.choice(
                      icon: AppIcons.workflowApproved,
                      label: _countLabel('Confirmed', metrics.confirmed),
                      selected: _filter == EventPaymentFilter.confirmed,
                      onSelected: () => setState(() => _filter = EventPaymentFilter.confirmed),
                    ),
                    HackzFilterChips.choice(
                      icon: AppIcons.clock,
                      label: _countLabel('Pending', metrics.pending),
                      selected: _filter == EventPaymentFilter.pending,
                      onSelected: () => setState(() => _filter = EventPaymentFilter.pending),
                    ),
                    HackzFilterChips.choice(
                      icon: AppIcons.error,
                      label: _countLabel('Exception', metrics.exceptions),
                      selected: _filter == EventPaymentFilter.exception,
                      onSelected: () => setState(() => _filter = EventPaymentFilter.exception),
                    ),
                  ],
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

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          toolbar,
          Expanded(
            child: PaymentEntriesView(
              entries: rows,
              ideaColumnLabel: widget.kind.payableItemLabel,
              emptyTitle: 'No payments found',
              emptyMessage: widget.entries.isEmpty
                  ? 'No ${widget.kind.payableItemLabel.toLowerCase()} payments for this event yet.'
                  : 'Try adjusting your search or filters.',
              onClearFilters: hasActiveFilters
                  ? () => setState(() {
                        _filter = EventPaymentFilter.all;
                        _searchController.clear();
                      })
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _countLabel(String label, int count) => count == 0 ? label : '$label ($count)';
}
