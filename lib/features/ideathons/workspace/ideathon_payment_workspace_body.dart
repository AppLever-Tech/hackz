import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../../utils/common_helpers.dart';
import '../../events/widgets/event_labeled_field.dart';
import '../../events/widgets/workspace_collapsible_section.dart';
import '../../payment/services/payment_finance_helpers.dart';
import '../../payment/widgets/payment_entries_view.dart';
import '../../payment/widgets/payment_metrics_row.dart';
import '../models/ideathon_model.dart';
import 'ideathon_payment_workspace_loader.dart';

class IdeathonPaymentWorkspaceBody extends StatelessWidget {
  const IdeathonPaymentWorkspaceBody({super.key, required this.vm});

  final IdeathonPaymentWorkspaceViewModel vm;

  static const double _labelWidth = 158;
  static const TextStyle _valueStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Color(0xFF0F172A),
  );
  static const TextStyle _metricAmountStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    height: 1.1,
    color: Color(0xFF0F172A),
  );

  @override
  Widget build(BuildContext context) {
    final IdeathonModel event = vm.event;
    final amounts = vm.payments.amounts;

    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        Text(
          event.name.trim().isEmpty ? 'Event' : event.name.trim(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        _field(icon: AppIcons.clock, label: 'Starts', value: formatDateTime(event.startDateTime.toLocal())),
        _field(icon: AppIcons.event, label: 'Ends', value: formatDateTime(event.endDateTime.toLocal())),
        _field(icon: AppIcons.ideas, label: 'Total ideas', value: '${event.ideaCount}'),
        _field(icon: AppIcons.organizations, label: 'Organisation', value: vm.organisationName),
        const SizedBox(height: 6),
        _field(
          icon: AppIcons.payments,
          label: PaymentMetricLabels.collection,
          value: PaymentFinanceHelpers.formatCurrency(amounts.collection),
          valueStyle: _metricAmountStyle,
        ),
        _field(
          icon: AppIcons.workflowApproved,
          label: PaymentMetricLabels.verified,
          value: PaymentFinanceHelpers.formatCurrency(amounts.confirmed),
          valueStyle: _metricAmountStyle,
        ),
        _field(
          icon: AppIcons.workflowPendingReview,
          label: PaymentMetricLabels.eventPending,
          value: PaymentFinanceHelpers.formatCurrency(amounts.pending),
          valueStyle: _metricAmountStyle,
        ),
        _field(
          icon: AppIcons.workflowRejected,
          label: PaymentMetricLabels.rejected,
          value: PaymentFinanceHelpers.formatCurrency(amounts.rejected),
          valueStyle: _metricAmountStyle,
          isLast: true,
        ),
        const SizedBox(height: 14),
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

  Widget _field({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
    bool isLast = false,
  }) {
    return EventLabeledField(
      icon: icon,
      label: label,
      value: value,
      labelWidth: _labelWidth,
      valueStyle: valueStyle ?? _valueStyle,
      isLast: isLast,
    );
  }
}
