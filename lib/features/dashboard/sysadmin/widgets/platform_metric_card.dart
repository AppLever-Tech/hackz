import 'package:flutter/material.dart';

import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';

class PlatformMetricCard {
  const PlatformMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final String? caption;

  DashboardMetricChipData toChipData() {
    return DashboardMetricChipData.single(
      label: label,
      value: value,
      color: accent,
      icon: icon,
      subtitle: caption,
      tooltip: caption ?? label,
    );
  }
}
