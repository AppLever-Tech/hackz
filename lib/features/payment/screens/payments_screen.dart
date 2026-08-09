import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/core/ui/inputs/filter_pill.dart';
import 'package:hackz/core/responsive/mobile_filter_pane_styles.dart';
import 'package:hackz/core/responsive/responsive_filter_bar.dart';
import 'package:hackz/core/responsive/responsive_helper.dart';
import 'package:hackz/core/ui/data_view/data_table_view.dart';

import '../models/payment_model.dart';
import '../services/department_payments_service.dart';
import '../services/payment_finance_helpers.dart';
import '../widgets/payment_detail_pane.dart';
import '../widgets/payment_metrics_row.dart';
import '../widgets/payment_table_columns.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Future<DepartmentPaymentsWorkspace> _future;
  final TextEditingController _searchController = TextEditingController();

  bool _showFilters = false;

  PaymentRecordStatus? _statusFilter;
  DepartmentPaymentDateFilter _dateFilter = DepartmentPaymentDateFilter.all;
  DepartmentPaymentVerificationFilter _verificationFilter = DepartmentPaymentVerificationFilter.all;

  @override
  void initState() {
    super.initState();
    _future = DepartmentPaymentsService.load(widget.user);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DepartmentPaymentContribution> _filtered(DepartmentPaymentsWorkspace workspace) {
    return DepartmentPaymentsService.filterContributions(
      source: workspace.contributions,
      search: _searchController.text,
      status: _statusFilter,
      dateFilter: _dateFilter,
      verificationFilter: _verificationFilter,
    );
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilter = null;
      _dateFilter = DepartmentPaymentDateFilter.all;
      _verificationFilter = DepartmentPaymentVerificationFilter.all;
    });
  }

  bool get _hasAnyActiveFilter =>
      _statusFilter != null ||
      _dateFilter != DepartmentPaymentDateFilter.all ||
      _verificationFilter != DepartmentPaymentVerificationFilter.all;

  PaymentTableActions _tableActions(DepartmentPaymentsWorkspace workspace) {
    return PaymentTableActions(
      onOpenDetail: (DepartmentPaymentContribution item) => _openPaymentDetail(context, workspace, item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DepartmentPaymentsWorkspace>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load payments: ${snapshot.error}'));
        }
        final workspace = snapshot.data!;
        final filtered = _filtered(workspace);
        final bool mobile = ResponsiveHelper.isMobile(context);
        final PaymentTableActions tableActions = _tableActions(workspace);

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final Widget header = _buildListHeader(
              context: context,
              workspace: workspace,
              filteredCount: filtered.length,
            );
            final Widget contentWidget = _buildList(
              workspace,
              filtered,
              mobile: mobile,
              actions: tableActions,
            );

            if (!hasBoundedHeight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  SizedBox(height: 480, child: contentWidget),
                ],
              );
            }

            if (mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  Expanded(child: contentWidget),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                header,
                Expanded(child: contentWidget),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildListHeader({
    required BuildContext context,
    required DepartmentPaymentsWorkspace workspace,
    required int filteredCount,
  }) {
    final bool compact = ResponsiveHelper.isMobile(context);
    final Widget metrics = PaymentMetricsRow(
      summary: workspace.summary,
      spacing: compact ? 8 : 10,
      runSpacing: compact ? 8 : 10,
    );
    final Widget searchBar = ResponsiveSearchFilterBar(
      searchController: _searchController,
      searchHint: 'Search idea, problem, team, mentor…',
      filtersExpanded: _showFilters,
      onToggleFilters: () => setState(() => _showFilters = !_showFilters),
      iconOnlyFilterOnMobile: true,
    );
    final Widget filters = AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: _buildFiltersPanel(context, workspace),
      crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 220),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          metrics,
          const SizedBox(height: 8),
          searchBar,
          const SizedBox(height: 6),
          filters,
          if (_hasAnyActiveFilter) ...<Widget>[
            const SizedBox(height: 6),
            _buildActiveFiltersRow(workspace),
          ],
          const SizedBox(height: 6),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        metrics,
        const SizedBox(height: 10),
        searchBar,
        const SizedBox(height: 8),
        filters,
        if (_hasAnyActiveFilter) ...<Widget>[
          SizedBox(height: compact ? 6 : 8),
          _buildActiveFiltersRow(workspace),
        ],
        SizedBox(height: compact ? 6 : 8),
        Text(
          'Showing $filteredCount contribution${filteredCount == 1 ? '' : 's'}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        SizedBox(height: compact ? 6 : 8),
      ],
    );
  }

  Widget _buildFiltersPanel(BuildContext context, DepartmentPaymentsWorkspace workspace) {
    final bool compact = MobileFilterPaneStyles.useCompact(context);
    final double sectionGap = MobileFilterPaneStyles.sectionGap(compact: compact);
    final double chipGap = MobileFilterPaneStyles.chipGap(compact: compact);
    final TextStyle sectionLabel = MobileFilterPaneStyles.sectionLabel(compact: compact);

    return MobileFilterPaneStyles.panelShell(
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveFilterChipRow(
            spacing: chipGap,
            runSpacing: chipGap,
            children: <Widget>[
              _statusFilterPill(
                compact: compact,
                selected: _statusFilter == null,
                icon: AppIcons.payments,
                label: 'All status',
                count: workspace.contributions.length,
                onTap: () => setState(() => _statusFilter = null),
              ),
              _statusFilterPill(
                compact: compact,
                selected: _statusFilter == PaymentRecordStatus.pending,
                icon: AppIcons.workflowPendingReview,
                label: 'Pending',
                count: workspace.summary.pendingCount,
                onTap: () => setState(() => _statusFilter = PaymentRecordStatus.pending),
              ),
              _statusFilterPill(
                compact: compact,
                selected: _statusFilter == PaymentRecordStatus.verified,
                icon: AppIcons.workflowApproved,
                label: 'Verified',
                count: workspace.summary.verifiedCount,
                onTap: () => setState(() => _statusFilter = PaymentRecordStatus.verified),
              ),
              _statusFilterPill(
                compact: compact,
                selected: _statusFilter == PaymentRecordStatus.rejected,
                icon: AppIcons.workflowRejected,
                label: 'Rejected',
                count: workspace.summary.rejectedCount,
                onTap: () => setState(() => _statusFilter = PaymentRecordStatus.rejected),
              ),
            ],
          ),
          SizedBox(height: sectionGap),
          Text('Payment date', style: sectionLabel),
          SizedBox(height: chipGap),
          Wrap(
            spacing: chipGap,
            runSpacing: chipGap,
            children: DepartmentPaymentDateFilter.values
                .map(
                  (f) => MobileFilterPaneStyles.filterChip(
                    compact: compact,
                    label: f.label,
                    selected: _dateFilter == f,
                    onSelected: (_) => setState(() => _dateFilter = f),
                  ),
                )
                .toList(growable: false),
          ),
          SizedBox(height: sectionGap),
          Text('Verification', style: sectionLabel),
          SizedBox(height: chipGap),
          Wrap(
            spacing: chipGap,
            runSpacing: chipGap,
            children: DepartmentPaymentVerificationFilter.values
                .map(
                  (f) => MobileFilterPaneStyles.filterChip(
                    compact: compact,
                    label: f.label,
                    selected: _verificationFilter == f,
                    onSelected: (_) => setState(() => _verificationFilter = f),
                  ),
                )
                .toList(growable: false),
          ),
          SizedBox(height: sectionGap),
          MobileFilterPaneStyles.footer(
            compact: compact,
            onClearAll: _clearAllFilters,
          ),
        ],
      ),
    );
  }

  Widget _statusFilterPill({
    required bool compact,
    required bool selected,
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    if (!compact) {
      return FilterPill(
        selected: selected,
        icon: icon,
        label: label,
        count: count,
        onTap: onTap,
      );
    }

    final Color fg = selected ? const Color(0xFF2E43C6) : const Color(0xFF475569);
    final Color bg = selected ? const Color(0xFFE8ECFF) : const Color(0xFFF1F5F9);
    final Color border = selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0);
    final String text = count == 0 ? label : '$label ($count)';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersRow(DepartmentPaymentsWorkspace workspace) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (_statusFilter != null)
          InputChip(
            avatar: Icon(PaymentFinanceHelpers.statusIcon(_statusFilter!), size: 16),
            label: Text(PaymentFinanceHelpers.statusLabel(_statusFilter!)),
            onDeleted: () => setState(() => _statusFilter = null),
          ),
        if (_dateFilter != DepartmentPaymentDateFilter.all)
          InputChip(
            label: Text(_dateFilter.label),
            onDeleted: () => setState(() => _dateFilter = DepartmentPaymentDateFilter.all),
          ),
        if (_verificationFilter != DepartmentPaymentVerificationFilter.all)
          InputChip(
            label: Text(_verificationFilter.label),
            onDeleted: () => setState(() => _verificationFilter = DepartmentPaymentVerificationFilter.all),
          ),
      ],
    );
  }

  Future<void> _openPaymentDetail(
    BuildContext context,
    DepartmentPaymentsWorkspace workspace,
    DepartmentPaymentContribution item,
  ) async {
    final DepartmentPaymentDetail? detail = workspace.detailFor(item.payment.paymentId);
    if (detail == null) {
      FeedbackService.showInfo(
        context,
        title: 'Payment details',
        message: 'Payment details are not available.',
      );
      return;
    }
    await showPaymentDetailDialog(context, detail: detail);
  }

  Widget _buildList(
    DepartmentPaymentsWorkspace workspace,
    List<DepartmentPaymentContribution> items, {
    required bool mobile,
    required PaymentTableActions actions,
  }) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No payment contributions match your filters.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    if (mobile) {
      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return PaymentListRowCard(
            item: items[index],
            actions: actions,
          );
        },
      );
    }

    return DataTableView<DepartmentPaymentContribution>(
      items: items,
      columns: PaymentTableColumns.build(actions: actions),
    );
  }
}

