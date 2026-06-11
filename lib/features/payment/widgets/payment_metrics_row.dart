import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../services/department_payments_service.dart';
import '../services/payment_finance_helpers.dart';
import 'payment_summary_card.dart';

/// Reusable metric row for department payments screens.
class PaymentMetricsRow extends StatelessWidget {
  const PaymentMetricsRow({
    super.key,
    required this.summary,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final DepartmentPaymentsSummary summary;
  final double spacing;
  final double runSpacing;

  int get _totalContributions => summary.verifiedCount + summary.pendingCount + summary.rejectedCount;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(_totalContributions, 'Contributions'),
        MetricKpiSegment.count(summary.verifiedCount, 'Verified'),
        MetricKpiSegment.count(summary.pendingCount, 'Pending'),
        MetricKpiSegment.count(summary.rejectedCount, 'Rejected'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        PaymentSummaryCard(
          label: 'Total department collection',
          value: PaymentFinanceHelpers.formatCurrency(summary.totalCollection),
          icon: AppIcons.payments,
          iconBgColor: const Color(0xFFE0F2FE),
          accentColor: const Color(0xFF0369A1),
          subtitle: '$_totalContributions contributions',
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
      ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveListMetrics(
      spacing: spacing,
      runSpacing: runSpacing,
      chips: _chips,
      stripSegments: _stripSegments,
    );
  }
}
