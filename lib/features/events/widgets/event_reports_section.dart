import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/event_report_item.dart';
import 'event_detail_section.dart';

/// Event Reports module reused by Ideathon and future Hackathon.
class EventReportsSection extends StatelessWidget {
  const EventReportsSection({
    super.key,
    required this.items,
    this.intro =
        'Download event documents when they are available. Certificate files use the organisation’s configured templates.',
  });

  final List<EventReportItem> items;
  final String intro;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        Text(
          intro,
          style: const TextStyle(fontSize: 12, height: 1.45, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          _ReportCard(item: items[i]),
        ],
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.item});

  final EventReportItem item;

  @override
  Widget build(BuildContext context) {
    return EventDetailSection(
      title: item.title,
      icon: item.icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.description,
            style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          if (!item.available)
            Text(
              item.unavailableReason,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: item.onDownload,
                icon: const Icon(AppIcons.download, size: 16),
                label: const Text('Download'),
              ),
            ),
        ],
      ),
    );
  }
}
