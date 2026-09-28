import 'package:flutter/material.dart';

import '../models/event_kind.dart';

/// Compact event-template pill for mixed event lists and overview.
class EventKindPill extends StatelessWidget {
  const EventKindPill({
    super.key,
    required this.kind,
    this.compact = true,
  });

  final EventKind kind;
  final bool compact;

  Color get _color => switch (kind) {
        EventKind.ideathon => const Color(0xFF6A38FF),
        EventKind.hackathon => const Color(0xFFEA580C),
        EventKind.researchPaper => const Color(0xFF0F766E),
      };

  @override
  Widget build(BuildContext context) {
    final Color color = _color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        kind.label,
        style: TextStyle(fontSize: compact ? 10.5 : 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
