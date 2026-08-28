import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
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
    this.collectionLabel = 'Total department collection',
    this.verifiedLabel = 'Verified payments',
    this.pendingLabel = 'Pending verifications',
    this.rejectedLabel = 'Rejected payments',
    this.collectionSubtitle,
    this.verifiedSubtitle,
    this.pendingSubtitle,
    this.rejectedSubtitle,
    this.stripSegments,
    this.forceChipGrid = false,
  });

  final DepartmentPaymentsSummary summary;
  final double spacing;
  final double runSpacing;
  final String collectionLabel;
  final String verifiedLabel;
  final String pendingLabel;
  final String rejectedLabel;
  final String? collectionSubtitle;
  final String? verifiedSubtitle;
  final String? pendingSubtitle;
  final String? rejectedSubtitle;
  final List<MetricKpiSegment>? stripSegments;
  final bool forceChipGrid;

  int get _totalContributions => summary.verifiedCount + summary.pendingCount + summary.rejectedCount;

  List<MetricKpiSegment> get _stripSegments =>
      stripSegments ??
      <MetricKpiSegment>[
        MetricKpiSegment.count(_totalContributions, 'Contributions'),
        MetricKpiSegment.count(summary.verifiedCount, 'Verified'),
        MetricKpiSegment.count(summary.pendingCount, 'Pending'),
        MetricKpiSegment.count(summary.rejectedCount, 'Rejected'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        PaymentSummaryCard(
          label: collectionLabel,
          value: PaymentFinanceHelpers.formatCurrency(summary.totalCollection),
          icon: AppIcons.payments,
          iconBgColor: const Color(0xFFE0F2FE),
          accentColor: const Color(0xFF0369A1),
          subtitle: collectionSubtitle ?? '$_totalContributions contributions',
        ).toChipData(),
        PaymentSummaryCard(
          label: verifiedLabel,
          value: PaymentFinanceHelpers.formatCurrency(summary.verifiedAmount),
          icon: AppIcons.workflowApproved,
          iconBgColor: const Color(0xFFECFDF5),
          accentColor: const Color(0xFF047857),
          subtitle: verifiedSubtitle ?? '${summary.verifiedCount} verified',
        ).toChipData(),
        PaymentSummaryCard(
          label: pendingLabel,
          value: PaymentFinanceHelpers.formatCurrency(summary.pendingAmount),
          icon: AppIcons.workflowPendingReview,
          iconBgColor: const Color(0xFFFFF7ED),
          accentColor: const Color(0xFFEA580C),
          subtitle: pendingSubtitle ?? '${summary.pendingCount} awaiting review',
        ).toChipData(),
        PaymentSummaryCard(
          label: rejectedLabel,
          value: PaymentFinanceHelpers.formatCurrency(summary.rejectedAmount),
          icon: AppIcons.workflowRejected,
          iconBgColor: const Color(0xFFFEF2F2),
          accentColor: const Color(0xFFB91C1C),
          subtitle: rejectedSubtitle ?? '${summary.rejectedCount} rejected',
        ).toChipData(),
      ];

  @override
  Widget build(BuildContext context) {
    if (forceChipGrid) {
      return ResponsiveMetricGrid(
        chips: _chips,
        spacing: spacing,
        runSpacing: runSpacing,
        compact: ResponsiveHelper.isMobile(context),
      );
    }
    return ResponsiveListMetrics(
      spacing: spacing,
      runSpacing: runSpacing,
      chips: _chips,
      stripSegments: _stripSegments,
    );
  }
}
