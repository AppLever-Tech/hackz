import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../chrome/dashboard_components.dart';
import '../services/coordinator_dashboard_service.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../../../../core/ui/common/time_frame_filter.dart';

class CoordinatorActivityFeed extends StatelessWidget {
  const CoordinatorActivityFeed({
    super.key,
    required this.activities,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  final List<CoordinatorActivityItem> activities;
  final CoordinatorDashboardTimeframe selectedTimeframe;
  final ValueChanged<CoordinatorDashboardTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    final List<CoordinatorActivityItem> filtered = activities
        .where(
          (CoordinatorActivityItem item) =>
              CoordinatorDashboardService.isWithinTimeframe(item.when, selectedTimeframe),
        )
        .toList(growable: false);

    return DashboardListCard(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      preset: DashboardListPreset.activity,
      headers: DashboardCardHeaders.timedList(
        headerRow: DashboardCardHeaderRow(
          title: 'Recent Activity',
          icon: AppIcons.clock,
          stackBelowWidth: 360,
          trailing: TimeFrameFilter<CoordinatorDashboardTimeframe>(
            options: CoordinatorDashboardTimeframe.values,
            selected: selectedTimeframe,
            labelBuilder: (CoordinatorDashboardTimeframe option) => option.label,
            onChanged: onTimeframeChanged,
            endPadding: 14,
          ),
        ),
        subtitle: '${selectedTimeframe.label} verification and validation operations',
        gapBeforeBody: DashboardLayoutTokens.activityHeaderGap,
      ),
      empty: const Align(
        alignment: Alignment.topLeft,
        child: Text('No activity in this period.'),
      ),
      itemCount: filtered.length,
      itemBuilder: (BuildContext context, int index) => _activityRow(filtered[index]),
    );
  }

  Widget _activityRow(CoordinatorActivityItem activity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: activity.tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activity.subtitle.isEmpty
                    ? _relativeTime(activity.when)
                    : '${activity.subtitle} · ${_relativeTime(activity.when)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _relativeTime(DateTime when) {
    final Duration diff = DateTime.now().difference(when);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
