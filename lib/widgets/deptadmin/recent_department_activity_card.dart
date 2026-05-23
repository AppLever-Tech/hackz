import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../screens/common/dashboard_components.dart';
import '../../utils/department_dashboard_service.dart';
import '../common/dashboard_panel_column.dart';
import '../common/dashboard_scrollable_list_layout.dart';
import '../common/time_frame_filter.dart';

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
    return DashboardPanelColumn(
      headers: <Widget>[
        DashboardCardHeaderRow(
          title: 'Recent Department Activity',
          icon: AppIcons.clock,
          trailing: TimeFrameFilter<DepartmentAnalyticsTimeframe>(
            options: DepartmentAnalyticsTimeframe.values,
            selected: selectedTimeframe,
            labelBuilder: (DepartmentAnalyticsTimeframe timeframe) => timeframe.label,
            onChanged: onTimeframeChanged,
          ),
        ),
        const SizedBox(height: 4),
        Text('${selectedTimeframe.label} operational updates', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
      ],
      listBuilder: ({required bool expandVertically}) => DashboardScrollableList(
        expandVertically: expandVertically,
        itemCount: filtered.length,
        rowStride: DashboardScrollableListLayout.departmentActivityRowStride,
        separatorHeight: DashboardScrollableListLayout.departmentActivitySeparatorHeight,
        empty: const Center(child: Text('No activity in this period')),
        itemBuilder: (BuildContext context, int index) => _eventRow(filtered[index]),
      ),
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
