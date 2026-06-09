import 'package:flutter/material.dart';

import 'package:hackz/constants/app_icons.dart';
import 'package:hackz/features/user/models/user_model.dart';
import 'package:hackz/screens/common/app_dialog_template.dart';
import 'package:hackz/shared/feedback/feedback.dart';
import 'package:hackz/shared/inputs/filter_pill.dart';
import 'package:hackz/widgets/dashboard/dashboard_metric_chips.dart';
import 'package:hackz/widgets/responsive/responsive_filter_bar.dart';
import 'package:hackz/widgets/responsive/responsive_metric_grid.dart';

import '../models/payment_model.dart';
import '../services/department_payments_service.dart';
import '../services/payment_finance_helpers.dart';
import '../widgets/payment_contribution_tile.dart';
import '../widgets/payment_detail_pane.dart';
import '../widgets/payment_summary_card.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

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

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final listPanel = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildSummaryRow(workspace.summary),
                const SizedBox(height: 10),
                ResponsiveSearchFilterBar(
                  searchController: _searchController,
                  searchHint: 'Search idea, problem, team, mentor…',
                  filtersExpanded: _showFilters,
                  onToggleFilters: () => setState(() => _showFilters = !_showFilters),
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildFiltersPanel(workspace),
                  crossFadeState: _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
                if (_hasAnyActiveFilter) ...<Widget>[
                  const SizedBox(height: 8),
                  _buildActiveFiltersRow(workspace),
                ],
                const SizedBox(height: 8),
                Text(
                  'Showing ${filtered.length} contribution${filtered.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (hasBoundedHeight)
                  Expanded(child: _buildList(workspace, filtered))
                else
                  SizedBox(height: 480, child: _buildList(workspace, filtered)),
              ],
            );

            return listPanel;
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(DepartmentPaymentsSummary summary) {
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        PaymentSummaryCard(
          label: 'Total department collection',
          value: PaymentFinanceHelpers.formatCurrency(summary.totalCollection),
          icon: AppIcons.payments,
          iconBgColor: const Color(0xFFE0F2FE),
          accentColor: const Color(0xFF0369A1),
          subtitle: '${summary.verifiedCount + summary.pendingCount + summary.rejectedCount} contributions',
        ).toChipData(),
        PaymentSummaryCard(
          label: 'Verified payments',
          value: PaymentFinanceHelpers.formatCurrency(summary.verifiedAmount),
          icon: AppIcons.workflowApproved,
          iconBgColor: const Color(0xFFECFDF5),
          accentColor: const Color(0xFF047857),
          subtitle: '${summary.verifiedCount} verified',
        ).toChipData(),
        PaymentSummaryCard(
          label: 'Pending verifications',
          value: PaymentFinanceHelpers.formatCurrency(summary.pendingAmount),
          icon: AppIcons.workflowPendingReview,
          iconBgColor: const Color(0xFFFFF7ED),
          accentColor: const Color(0xFFEA580C),
          subtitle: '${summary.pendingCount} awaiting review',
        ).toChipData(),
        PaymentSummaryCard(
          label: 'Rejected payments',
          value: PaymentFinanceHelpers.formatCurrency(summary.rejectedAmount),
          icon: AppIcons.statusRejected,
          iconBgColor: const Color(0xFFFEF2F2),
          accentColor: const Color(0xFFB91C1C),
          subtitle: '${summary.rejectedCount} rejected',
        ).toChipData(),
      ],
    );
  }

  Widget _buildFiltersPanel(DepartmentPaymentsWorkspace workspace) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveFilterChipRow(
            children: <Widget>[
              FilterPill(
                selected: _statusFilter == null,
                icon: AppIcons.payments,
                label: 'All status',
                count: workspace.contributions.length,
                onTap: () => setState(() => _statusFilter = null),
              ),
              FilterPill(
                selected: _statusFilter == PaymentRecordStatus.pending,
                icon: AppIcons.workflowPendingReview,
                label: 'Pending',
                count: workspace.summary.pendingCount,
                onTap: () => setState(() => _statusFilter = PaymentRecordStatus.pending),
              ),
              FilterPill(
                selected: _statusFilter == PaymentRecordStatus.verified,
                icon: AppIcons.workflowApproved,
                label: 'Verified',
                count: workspace.summary.verifiedCount,
                onTap: () => setState(() => _statusFilter = PaymentRecordStatus.verified),
              ),
              FilterPill(
                selected: _statusFilter == PaymentRecordStatus.rejected,
                icon: AppIcons.statusRejected,
                label: 'Rejected',
                count: workspace.summary.rejectedCount,
                onTap: () => setState(() => _statusFilter = PaymentRecordStatus.rejected),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Payment date', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DepartmentPaymentDateFilter.values
                .map(
                  (f) => FilterChip(
                    label: Text(f.label),
                    selected: _dateFilter == f,
                    onSelected: (_) => setState(() => _dateFilter = f),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          const Text('Verification', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DepartmentPaymentVerificationFilter.values
                .map(
                  (f) => FilterChip(
                    label: Text(f.label),
                    selected: _verificationFilter == f,
                    onSelected: (_) => setState(() => _verificationFilter = f),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(onPressed: _clearAllFilters, child: const Text('Clear All')),
            ],
          ),
        ],
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

  Future<void> _openPaymentDetail(BuildContext context, DepartmentPaymentsWorkspace workspace, DepartmentPaymentContribution item) async {
    final DepartmentPaymentDetail? detail = workspace.detailFor(item.payment.paymentId);
    if (detail == null) {
      FeedbackService.showInfo(
        context,
        title: 'Payment details',
        message: 'Payment details are not available.',
      );
      return;
    }
    await showAppDialog<void>(
      context: context,
      width: DialogWidthPreset.wide,
      child: PaymentDetailPane(detail: detail),
    );
  }

  Widget _buildList(DepartmentPaymentsWorkspace workspace, List<DepartmentPaymentContribution> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No payment contributions match your filters.', style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return PaymentContributionTile(
          item: item,
          selected: false,
          onTap: () => _openPaymentDetail(context, workspace, item),
          onOpenWorkspace: () => WorkspaceNavigator.openPayment(context, item.payment.paymentId),
          onOpenProblem: item.payment.problemId.trim().isEmpty
              ? null
              : () => WorkspaceNavigator.openProblem(context, item.payment.problemId),
        );
      },
    );
  }
}
