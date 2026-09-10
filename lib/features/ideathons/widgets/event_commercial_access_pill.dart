import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/event_commercial_access.dart';

/// Commercial activation flag only. Not an event lifecycle pill.
class EventCommercialAccessPill extends StatelessWidget {
  const EventCommercialAccessPill({
    super.key,
    this.compact = true,
  });

  final bool compact;

  static Widget? maybe(EventCommercialAccess access, {bool compact = true}) {
    if (!access.isPending) return null;
    return EventCommercialAccessPill(compact: compact);
  }

  @override
  Widget build(BuildContext context) {
    const Color color = Color(0xFFB45309);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(AppIcons.accountPending, size: compact ? 11 : 13, color: color),
          const SizedBox(width: 4),
          Text(
            'Activation pending',
            style: TextStyle(fontSize: compact ? 10.5 : 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
