import 'package:flutter/material.dart';

import '../../utils/department_dashboard_service.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            const title = Text('Recent Department Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)));
            final filter = TimeFrameFilter<DepartmentAnalyticsTimeframe>(
              options: DepartmentAnalyticsTimeframe.values,
              selected: selectedTimeframe,
              labelBuilder: (DepartmentAnalyticsTimeframe timeframe) => timeframe.label,
              onChanged: onTimeframeChanged,
            );
            if (c.maxWidth < 720) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[title, const SizedBox(height: 10), filter]);
            }
            return Row(children: <Widget>[Expanded(child: title), const SizedBox(width: 12), filter]);
          },
        ),
        const SizedBox(height: 4),
        Text('${selectedTimeframe.label} operational updates', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No activity in this period'))
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (BuildContext context, int index) {
                    final event = filtered[index];
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
                  },
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
