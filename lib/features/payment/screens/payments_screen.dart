import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/core/ui/feedback/feedback.dart';
import 'package:hackz/core/responsive/responsive_filter_bar.dart';
import 'package:hackz/core/responsive/responsive_helper.dart';
import 'package:hackz/core/ui/data_view/data_table_view.dart';
import 'package:hackz/core/ui/filters/hackz_filter_pane.dart';
import 'package:hackz/features/dashboard/chrome/empty_search_state.dart';

import '../models/payment_model.dart';
import '../services/department_payments_service.dart';
import '../services/payment_finance_helpers.dart';
import '../widgets/payment_detail_pane.dart';
import '../widgets/payment_metrics_row.dart';
import '../widgets/payment_table_columns.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    super.key,
    required this.user,
    this.ledTeamsOnly = false,
  });

  final UserModel user;
  final bool ledTeamsOnly;

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
    _future = DepartmentPaymentsService.load(widget.user, ledTeamsOnly: widget.ledTeamsOnly);
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
      searchHint: 'Search idea, problem, team…',
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
    return HackzFilterPane(
      onClearAll: _clearAllFilters,
      sections: <Widget>[
        HackzFilterSection.chips(
          icon: AppIcons.payments,
          label: 'Status',
          chips: <Widget>[
            HackzFilterChips.choice(
              icon: AppIcons.payments,
              label: _countLabel('All status', workspace.contributions.length),
              selected: _statusFilter == null,
              onSelected: () => setState(() => _statusFilter = null),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.workflowPendingReview,
              label: _countLabel('Pending', workspace.summary.pendingCount),
              selected: _statusFilter == PaymentRecordStatus.pending,
              onSelected: () => setState(() => _statusFilter = PaymentRecordStatus.pending),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.workflowApproved,
              label: _countLabel('Verified', workspace.summary.verifiedCount),
              selected: _statusFilter == PaymentRecordStatus.verified,
              onSelected: () => setState(() => _statusFilter = PaymentRecordStatus.verified),
            ),
            HackzFilterChips.choice(
              icon: AppIcons.workflowRejected,
              label: _countLabel('Rejected', workspace.summary.rejectedCount),
              selected: _statusFilter == PaymentRecordStatus.rejected,
              onSelected: () => setState(() => _statusFilter = PaymentRecordStatus.rejected),
            ),
          ],
        ),
        HackzFilterSection.chips(
          icon: AppIcons.event,
          label: 'Payment date',
          chips: DepartmentPaymentDateFilter.values
              .map(
                (DepartmentPaymentDateFilter f) => HackzFilterChips.choice(
                  label: f.label,
                  selected: _dateFilter == f,
                  onSelected: () => setState(() => _dateFilter = f),
                ),
              )
              .toList(growable: false),
        ),
        HackzFilterSection.chips(
          icon: AppIcons.verification,
          label: 'Verification',
          chips: DepartmentPaymentVerificationFilter.values
              .map(
                (DepartmentPaymentVerificationFilter f) => HackzFilterChips.choice(
                  label: f.label,
                  selected: _verificationFilter == f,
                  onSelected: () => setState(() => _verificationFilter = f),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  String _countLabel(String label, int count) => count == 0 ? label : '$label ($count)';

  Widget _buildActiveFiltersRow(DepartmentPaymentsWorkspace workspace) {
    return HackzActiveFiltersRow(
      chips: <Widget>[
        if (_statusFilter != null)
          HackzFilterChips.applied(
            icon: PaymentFinanceHelpers.statusIcon(_statusFilter!),
            label: PaymentFinanceHelpers.statusLabel(_statusFilter!),
            onDeleted: () => setState(() => _statusFilter = null),
          ),
        if (_dateFilter != DepartmentPaymentDateFilter.all)
          HackzFilterChips.applied(
            icon: AppIcons.event,
            label: _dateFilter.label,
            onDeleted: () => setState(() => _dateFilter = DepartmentPaymentDateFilter.all),
          ),
        if (_verificationFilter != DepartmentPaymentVerificationFilter.all)
          HackzFilterChips.applied(
            icon: AppIcons.verification,
            label: _verificationFilter.label,
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
      return EmptySearchState.payments(
        onClearSearch: () {
          _searchController.clear();
          _clearAllFilters();
        },
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

