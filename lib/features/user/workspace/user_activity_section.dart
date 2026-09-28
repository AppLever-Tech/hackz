import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import 'user_workspace_loader.dart';

class UserActivitySection extends StatelessWidget {
  const UserActivitySection({super.key, required this.items});

  final List<UserActivityItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _heading(),
          const SizedBox(height: 8),
          Text(
            'No recent activity summaries are available yet.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _heading(),
        const SizedBox(height: 10),
        ...items.map((UserActivityItem e) => _ActivityTile(item: e)),
      ],
    );
  }

  Widget _heading() {
    return Text(
      'Recent activity',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final UserActivityItem item;

  @override
  Widget build(BuildContext context) {
    final double gap = ResponsiveHelper.isMobile(context) ? 8 : 10;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EBF5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(item.icon, size: 18, color: const Color(0xFF57629A)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
