import 'package:flutter/material.dart';

import '../models/feedback_status.dart';

class FeedbackStatusPill extends StatelessWidget {
  const FeedbackStatusPill({
    super.key,
    required this.status,
    this.compact = false,
  });

  final FeedbackStatus status;
  final bool compact;

  (Color, Color) _colors() {
    return switch (status) {
      FeedbackStatus.open => (const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      FeedbackStatus.inReview => (const Color(0xFFD97706), const Color(0xFFFFFBEB)),
      FeedbackStatus.completed => (const Color(0xFF059669), const Color(0xFFECFDF5)),
      FeedbackStatus.closed => (const Color(0xFF64748B), const Color(0xFFF1F5F9)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = _colors();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
