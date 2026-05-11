import 'package:flutter/material.dart';

import '../../screens/common/dashboard_components.dart';

class DepartmentMetricCard extends StatelessWidget {
  const DepartmentMetricCard({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashboardCountCard(
          value: value,
          label: label,
          icon: icon,
          iconBgColor: iconBgColor,
        ),
        if (footnote != null && footnote!.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            footnote!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
    if (tooltip == null || tooltip!.trim().isEmpty) return card;
    return Tooltip(message: tooltip!, child: card);
  }
}
