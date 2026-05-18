import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import '../../utils/coordinator_dashboard_service.dart';
import 'coordinator_panel_card.dart';

class CoordinatorActivityFeed extends StatelessWidget {
  const CoordinatorActivityFeed({super.key, required this.activities});

  final List<CoordinatorActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    final inFixedPanel = ResponsiveHelper.isDesktopOrWider(context);
    final list = activities.isEmpty
        ? const Center(child: Text('No coordinator activity yet.'))
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: !inFixedPanel,
            physics: inFixedPanel ? null : const NeverScrollableScrollPhysics(),
            itemCount: activities.length.clamp(0, 8).toInt(),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final activity = activities[index];
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
                        Text(activity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(activity.subtitle.isEmpty ? _dateLabel(activity.when) : '${activity.subtitle} - ${_dateLabel(activity.when)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              );
            },
          );

    return CoordinatorPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Recent Coordinator Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Recent verification and validation operations', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (inFixedPanel) Expanded(child: list) else list,
        ],
      ),
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

