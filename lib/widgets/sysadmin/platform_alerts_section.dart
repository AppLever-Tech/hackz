import 'package:flutter/material.dart';

import '../../utils/sysadmin_dashboard_service.dart';
import '../common/dashboard_panel_column.dart';
import '../common/dashboard_scrollable_list_layout.dart';

class PlatformAlertsSection extends StatelessWidget {
  const PlatformAlertsSection({
    super.key,
    required this.alerts,
  });

  final List<PlatformAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return DashboardPanelColumn(
      headers: <Widget>[
        const Text(
          'Platform Alerts',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          'Operational signals that may need attention',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
      ],
      listBuilder: ({required bool expandVertically}) => DashboardScrollableList(
        expandVertically: expandVertically,
        itemCount: alerts.length,
        rowStride: DashboardScrollableListLayout.alertRowStride,
        separatorHeight: DashboardScrollableListLayout.alertSeparatorHeight,
        itemBuilder: (BuildContext context, int index) => _alertCard(alerts[index]),
      ),
    );
  }

  Widget _alertCard(PlatformAlert alert) {
    final _AlertStyle style = _style(alert.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(style.icon, size: 20, color: style.foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  alert.title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: style.foreground),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _AlertStyle _style(PlatformAlertSeverity severity) {
    switch (severity) {
      case PlatformAlertSeverity.critical:
        return const _AlertStyle(
          background: Color(0xFFFEF2F2),
          border: Color(0xFFFECACA),
          foreground: Color(0xFFB91C1C),
          icon: Icons.error_outline_rounded,
        );
      case PlatformAlertSeverity.warning:
        return const _AlertStyle(
          background: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          foreground: Color(0xFFC2410C),
          icon: Icons.warning_amber_rounded,
        );
      case PlatformAlertSeverity.info:
        return const _AlertStyle(
          background: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
          foreground: Color(0xFF1D4ED8),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _AlertStyle {
  const _AlertStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;
}
