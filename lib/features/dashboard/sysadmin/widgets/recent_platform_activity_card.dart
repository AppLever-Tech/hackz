import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../chrome/dashboard_components.dart';
import '../services/sysadmin_dashboard_service.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../../../../core/ui/common/time_frame_filter.dart';

class RecentPlatformActivityCard extends StatelessWidget {
  const RecentPlatformActivityCard({
    super.key,
    required this.events,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  final List<PlatformActivityEvent> events;
  final PlatformAnalyticsTimeframe selectedTimeframe;
  final ValueChanged<PlatformAnalyticsTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    final List<PlatformActivityEvent> filtered = events
        .where((PlatformActivityEvent event) => SysAdminDashboardService.isWithinTimeframe(event.when, selectedTimeframe))
        .take(8)
        .toList(growable: false);
    return DashboardListCard(
      preset: DashboardListPreset.activity,
      emptyHeight: DashboardLayoutTokens.listActivityEmptyHeight,
      empty: const Center(child: Text('No platform events for this timeframe')),
      headers: DashboardCardHeaders.timedList(
        headerRow: DashboardCardHeaderRow(
          title: 'Recent Platform Activity',
          icon: AppIcons.clock,
          trailing: TimeFrameFilter<PlatformAnalyticsTimeframe>(
            options: PlatformAnalyticsTimeframe.values,
            selected: selectedTimeframe,
            labelBuilder: (PlatformAnalyticsTimeframe timeframe) => timeframe.label,
            onChanged: onTimeframeChanged,
          ),
        ),
        subtitle: '${selectedTimeframe.label} operational events across the ecosystem',
        subtitleColor: Colors.grey.shade600,
      ),
      itemCount: filtered.length,
      itemBuilder: (BuildContext context, int index) => _eventRow(filtered[index]),
    );
  }

  Widget _eventRow(PlatformActivityEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: event.tint.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(event.icon, color: event.tint, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                event.subtitle.trim().isEmpty ? 'Platform update' : event.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _relative(event.when),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  String _relative(DateTime when) {
    final Duration diff = DateTime.now().difference(when);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
