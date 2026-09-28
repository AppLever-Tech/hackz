import 'package:flutter/material.dart';

import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';

class OperationalMetricCard {
  const OperationalMetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    this.footnote,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final String? footnote;

  DashboardMetricChipData toChipData() {
    return DashboardMetricChipData.single(
      label: label,
      value: value,
      color: dashboardMetricAccentFromIconBg(iconBgColor),
      icon: icon,
      subtitle: footnote,
      tooltip: footnote ?? label,
    );
  }
}
