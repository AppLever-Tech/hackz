import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../responsive/responsive_helper.dart';
import '../../screens/common/dashboard_components.dart';
import '../../utils/sysadmin_dashboard_service.dart';
import '../common/time_frame_filter.dart';

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

  static const int _kScrollAfterRows = 5;
  static const double _kRowStride = 60;

  @override
  Widget build(BuildContext context) {
    final List<PlatformActivityEvent> filtered = events
        .where((PlatformActivityEvent event) => SysAdminDashboardService.isWithinTimeframe(event.when, selectedTimeframe))
        .take(8)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashboardCardHeaderRow(
          title: 'Recent Platform Activity',
          icon: AppIcons.clock,
          trailing: TimeFrameFilter<PlatformAnalyticsTimeframe>(
            options: PlatformAnalyticsTimeframe.values,
            selected: selectedTimeframe,
            labelBuilder: (PlatformAnalyticsTimeframe timeframe) => timeframe.label,
            onChanged: onTimeframeChanged,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${selectedTimeframe.label} operational events across the ecosystem',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        _buildActivityList(context, filtered),
      ],
    );
  }

  Widget _buildActivityList(BuildContext context, List<PlatformActivityEvent> filtered) {
    final bool inFixedPanel = ResponsiveHelper.isDesktopOrWider(context);
    if (filtered.isEmpty) {
      const Widget empty = SizedBox(height: 130, child: Center(child: Text('No platform events for this timeframe')));
      return inFixedPanel ? const Expanded(child: empty) : empty;
    }

    final int visibleRows = filtered.length > _kScrollAfterRows ? _kScrollAfterRows : filtered.length;
    final double listHeight = visibleRows * _kRowStride;
    final Widget list = ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: !inFixedPanel,
      physics: filtered.length > _kScrollAfterRows || !inFixedPanel
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) => _eventRow(filtered[index]),
    );

    if (!inFixedPanel) {
      return list;
    }

    return Expanded(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: listHeight,
          width: double.infinity,
          child: list,
        ),
      ),
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
