import 'package:flutter/material.dart';

import '../../screens/common/dashboard_components.dart';

class PlatformMetricCard extends StatelessWidget {
  const PlatformMetricCard({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: caption ?? label,
      child: DashboardCountCard(
        value: value,
        label: label,
        icon: icon,
        iconBgColor: accent.withOpacity(0.12),
      ),
    );
  }
}
