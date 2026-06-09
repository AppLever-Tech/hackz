import 'package:flutter/material.dart';

import '../../../widgets/dashboard/dashboard_metric_chips.dart';

/// Responsive metric chips: 2 per row on mobile/tablet, 4 on desktop.
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.chips,
    this.spacing,
    this.runSpacing,
  });

  final List<DashboardMetricChipData> chips;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    return DashboardMetricChipGrid(
      chips: chips,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }
}
