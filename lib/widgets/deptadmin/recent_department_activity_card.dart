import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../screens/common/dashboard_components.dart';
import '../../utils/department_dashboard_service.dart';
import '../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../../core/ui/common/time_frame_filter.dart';

class RecentDepartmentActivityCard extends StatelessWidget {
  const RecentDepartmentActivityCard({
    super.key,
    required this.events,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  final List<DepartmentActivityEvent> events;
  final DepartmentAnalyticsTimeframe selectedTimeframe;
  final ValueChanged<DepartmentAnalyticsTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = events
        .where((event) => DepartmentDashboardService.isWithinTimeframe(event.when, selectedTimeframe))
        .take(12)
        .toList(growable: false);
    return DashboardListCard(
      preset: DashboardListPreset.departmentActivity,
      empty: const Center(child: Text('No activity in this period')),
      headers: DashboardCardHeaders.timedList(
        headerRow: DashboardCardHeaderRow(
          title: 'Recent Department Activity',
          icon: AppIcons.clock,
          trailing: TimeFrameFilter<DepartmentAnalyticsTimeframe>(
            options: DepartmentAnalyticsTimeframe.values,
            selected: selectedTimeframe,
            labelBuilder: (DepartmentAnalyticsTimeframe timeframe) => timeframe.label,
            onChanged: onTimeframeChanged,
          ),
        ),
        subtitle: '${selectedTimeframe.label} operational updates',
      ),
      itemCount: filtered.length,
      itemBuilder: (BuildContext context, int index) => _eventRow(filtered[index]),
    );
  }

  Widget _eventRow(DepartmentActivityEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: event.tint.withOpacity(0.11), shape: BoxShape.circle),
          child: Icon(event.icon, size: 18, color: event.tint),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(event.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(
                event.subtitle.isEmpty ? _relativeTime(event.when) : '${event.subtitle} · ${_relativeTime(event.when)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
