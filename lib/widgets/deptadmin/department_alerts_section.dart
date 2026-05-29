import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/department_dashboard_service.dart';
import '../common/dashboard_card/dashboard_card_layout.dart';

class DepartmentAlertsSection extends StatelessWidget {
  const DepartmentAlertsSection({super.key, required this.alerts});

  final List<DepartmentAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return DashboardListCard(
      preset: DashboardListPreset.alert,
      headers: DashboardCardHeaders.sectionTitle(
        title: 'Pending Approvals & Alerts',
        subtitle: 'Operational items that need department attention',
      ),
      itemCount: alerts.length,
      itemBuilder: (BuildContext context, int index) => _alertCard(alerts[index]),
    );
  }

  Widget _alertCard(DepartmentAlert alert) {
    final color = _color(alert.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.75), shape: BoxShape.circle),
            child: Icon(_icon(alert.severity), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(alert.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(alert.message, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _color(DepartmentAlertSeverity severity) {
    switch (severity) {
      case DepartmentAlertSeverity.info:
        return const Color(0xFF0EA5E9);
      case DepartmentAlertSeverity.warning:
        return const Color(0xFFF59E0B);
      case DepartmentAlertSeverity.critical:
        return const Color(0xFFDC2626);
    }
  }

  IconData _icon(DepartmentAlertSeverity severity) {
    switch (severity) {
      case DepartmentAlertSeverity.info:
        return AppIcons.info;
      case DepartmentAlertSeverity.warning:
        return AppIcons.pendingUsers;
      case DepartmentAlertSeverity.critical:
        return AppIcons.verification;
    }
  }
}
