import 'package:flutter/material.dart';

import 'package:hackz/widgets/dashboard/dashboard_metric_chips.dart';

/// Finance metric chip data for payment operations dashboards.
class PaymentSummaryCard {
  const PaymentSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBgColor,
    this.subtitle,
    this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBgColor;
  final String? subtitle;
  final Color? accentColor;

  DashboardMetricChipData toChipData() {
    return DashboardMetricChipData.single(
      label: label,
      value: value,
      color: accentColor ?? dashboardMetricAccentFromIconBg(iconBgColor),
      icon: icon,
      subtitle: subtitle,
      tooltip: subtitle ?? label,
    );
  }
}
