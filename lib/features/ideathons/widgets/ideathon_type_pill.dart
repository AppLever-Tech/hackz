import 'package:flutter/material.dart';

import '../models/ideathon_type.dart';

/// Compact Internal / External pill for Ideathon list and overview.
class IdeathonTypePill extends StatelessWidget {
  const IdeathonTypePill({
    super.key,
    required this.type,
    this.compact = true,
  });

  final IdeathonType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool external = type == IdeathonType.external;
    final Color color = external ? const Color(0xFF6A38FF) : const Color(0xFF0369A1);
    return Tooltip(
      message: type.helpText,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          type.label,
          style: TextStyle(fontSize: compact ? 10.5 : 12, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}
