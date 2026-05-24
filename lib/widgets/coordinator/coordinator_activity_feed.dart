import 'package:flutter/material.dart';

import '../../utils/coordinator_dashboard_service.dart';
import '../common/dashboard_card/dashboard_card_layout.dart';
import 'coordinator_panel_card.dart';

class CoordinatorActivityFeed extends StatelessWidget {
  const CoordinatorActivityFeed({super.key, required this.activities});

  final List<CoordinatorActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final int itemCount = activities.length.clamp(0, 8).toInt();
    return CoordinatorPanelCard(
      child: DashboardListCard(
        preset: DashboardListPreset.activity,
        separatorHeight: 10,
        headers: const <Widget>[
          Text('Recent Coordinator Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          SizedBox(height: DashboardLayoutTokens.titleSubtitleGap),
          Text('Recent verification and validation operations', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          SizedBox(height: DashboardLayoutTokens.iconCountHeaderGap),
        ],
        empty: const Center(child: Text('No coordinator activity yet.')),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) => _activityRow(activities[index]),
      ),
    );
  }

  Widget _activityRow(CoordinatorActivityItem activity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: activity.tint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(activity.icon, size: 18, color: activity.tint),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                activity.subtitle.isEmpty ? _dateLabel(activity.when) : '${activity.subtitle} - ${_dateLabel(activity.when)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _dateLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
