import 'package:flutter/material.dart';

import '../../../utils/common_helpers.dart';

/// Reusable vertical lifecycle timeline (problem statements, ideas, etc.).
class LifecycleTimeline extends StatelessWidget {
  const LifecycleTimeline({
    super.key,
    required this.title,
    required this.subtitle,
    required this.events,
  });

  final String title;
  final String subtitle;
  final List<LifecycleTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        ...List<Widget>.generate(events.length, (int index) {
          return LifecycleTimelineTile(
            event: events[index],
            isLast: index == events.length - 1,
          );
        }),
      ],
    );
  }
}

class LifecycleTimelineEvent {
  const LifecycleTimelineEvent({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime? when;
  final IconData icon;
  final Color color;
}

class LifecycleTimelineTile extends StatelessWidget {
  const LifecycleTimelineTile({
    super.key,
    required this.event,
    required this.isLast,
  });

  final LifecycleTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: event.color.withValues(alpha: 0.35)),
                ),
                child: Icon(event.icon, size: 15, color: event.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                  ),
                  if (event.when != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(event.when!),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
