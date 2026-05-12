import 'package:flutter/material.dart';

import '../../screens/common/dashboard_components.dart';

class OperationalMetricCard extends StatelessWidget {
  const OperationalMetricCard({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: footnote ?? label,
      child: DashboardCountCard(
        value: value,
        label: label,
        icon: icon,
        iconBgColor: iconBgColor,
      ),
    );
  }
}
