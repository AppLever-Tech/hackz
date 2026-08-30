import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../events/widgets/event_labeled_field.dart';
import '../../events/widgets/workspace_collapsible_section.dart';
import '../../payment/services/payment_finance_helpers.dart';
import '../../payment/widgets/payment_entries_view.dart';
import '../../payment/widgets/payment_metrics_row.dart';
import '../widgets/ideathon_event_workspace_header.dart';
import 'ideathon_payment_workspace_loader.dart';

class IdeathonPaymentWorkspaceBody extends StatelessWidget {
  const IdeathonPaymentWorkspaceBody({super.key, required this.vm});

  final IdeathonPaymentWorkspaceViewModel vm;

  static const double _metricLabelWidth = 158;
  static const TextStyle _metricAmountStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    height: 1.1,
    color: Color(0xFF0F172A),
  );

  @override
  Widget build(BuildContext context) {
    final amounts = vm.payments.amounts;

    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        ideathonEventWorkspaceHeader(
          event: vm.event,
          organisationName: vm.organisationName,
        ),
        const SizedBox(height: 14),
        WorkspaceCollapsibleSection(
          title: 'Payments',
          icon: AppIcons.payments,
          collapsible: false,
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _metric(
                icon: AppIcons.payments,
                label: PaymentMetricLabels.collection,
                value: PaymentFinanceHelpers.formatCurrency(amounts.collection),
              ),
              _metric(
                icon: AppIcons.workflowApproved,
                label: PaymentMetricLabels.verified,
                value: PaymentFinanceHelpers.formatCurrency(amounts.confirmed),
              ),
              _metric(
                icon: AppIcons.workflowPendingReview,
                label: PaymentMetricLabels.eventPending,
                value: PaymentFinanceHelpers.formatCurrency(amounts.pending),
              ),
              _metric(
                icon: AppIcons.workflowRejected,
                label: PaymentMetricLabels.rejected,
                value: PaymentFinanceHelpers.formatCurrency(amounts.rejected),
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        WorkspaceCollapsibleSection(
          title: 'Ideas',
          icon: AppIcons.ideas,
          count: vm.entries.length,
          child: PaymentEntriesView(
            entries: vm.entries,
            ideaColumnLabel: 'Idea',
            emptyTitle: 'No payments found',
            emptyMessage: 'No idea payments for this event yet.',
            compactIdeaPaymentRows: true,
          ),
        ),
      ],
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return EventLabeledField(
      icon: icon,
      label: label,
      value: value,
      labelWidth: _metricLabelWidth,
      valueStyle: _metricAmountStyle,
      valueTextAlign: TextAlign.end,
      isLast: isLast,
    );
  }
}
