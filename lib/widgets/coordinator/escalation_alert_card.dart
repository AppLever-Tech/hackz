import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/coordinator_dashboard_service.dart';

class EscalationAlertCard extends StatelessWidget {
  const EscalationAlertCard({super.key, required this.alert});

  final CoordinatorEscalation alert;

  @override
  Widget build(BuildContext context) {
    final colors = switch (alert.severity) {
      CoordinatorEscalationSeverity.info => (bg: const Color(0xFFEFF6FF), fg: const Color(0xFF2563EB), border: const Color(0xFFBFDBFE)),
      CoordinatorEscalationSeverity.warning => (bg: const Color(0xFFFFF7ED), fg: const Color(0xFFEA580C), border: const Color(0xFFFED7AA)),
      CoordinatorEscalationSeverity.critical => (bg: const Color(0xFFFEF2F2), fg: const Color(0xFFDC2626), border: const Color(0xFFFECACA)),
    };
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(AppIcons.info, color: colors.fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(alert.title, style: TextStyle(fontSize: 13, color: colors.fg, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(alert.message, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
