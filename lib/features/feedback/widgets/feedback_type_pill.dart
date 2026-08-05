import 'package:flutter/material.dart';

import '../models/feedback_type.dart';

class FeedbackTypePill extends StatelessWidget {
  const FeedbackTypePill({
    super.key,
    required this.type,
    this.compact = false,
  });

  final FeedbackType type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color fg = type == FeedbackType.issue
        ? const Color(0xFFDC2626)
        : const Color(0xFF7C3AED);
    final Color bg = type == FeedbackType.issue
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF5F3FF);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
