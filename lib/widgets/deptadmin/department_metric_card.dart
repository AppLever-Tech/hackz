import 'package:flutter/material.dart';

import '../dashboard/dashboard_metric_chips.dart';

class DepartmentMetricCard {
  const DepartmentMetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    this.tooltip,
    this.footnote,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final String? tooltip;
  final String? footnote;

  DashboardMetricChipData toChipData() {
    return DashboardMetricChipData.single(
      label: label,
      value: value,
      color: dashboardMetricAccentFromIconBg(iconBgColor),
      icon: icon,
      subtitle: footnote,
      tooltip: tooltip,
    );
  }
}
