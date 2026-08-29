import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// Compact header chip used on Event / Problem / Idea details pages.
class EventMetaChip extends StatelessWidget {
  const EventMetaChip({
    super.key,
    required this.label,
    this.icon = AppIcons.info,
    this.color = const Color(0xFF475569),
    this.fontWeight = FontWeight.w700,
  });

  final String label;
  final IconData icon;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = (MediaQuery.sizeOf(context).width - 48).clamp(160.0, 560.0);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: fontWeight, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
