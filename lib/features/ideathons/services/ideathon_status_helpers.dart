import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/ideathon_status.dart';

abstract final class IdeathonStatusHelpers {
  IdeathonStatusHelpers._();

  static String label(IdeathonStatus status) {
    return switch (status) {
      IdeathonStatus.draft => 'Draft',
      IdeathonStatus.scheduled => 'Scheduled',
      IdeathonStatus.inProgress => 'In Progress',
      IdeathonStatus.completed => 'Completed',
      IdeathonStatus.archived => 'Archived',
    };
  }

  static Color color(IdeathonStatus status) {
    return switch (status) {
      IdeathonStatus.draft => const Color(0xFF64748B),
      IdeathonStatus.scheduled => const Color(0xFF0EA5E9),
      IdeathonStatus.inProgress => const Color(0xFF6366F1),
      IdeathonStatus.completed => const Color(0xFF059669),
      IdeathonStatus.archived => const Color(0xFF94A3B8),
    };
  }

  static Color background(IdeathonStatus status) => color(status).withValues(alpha: 0.12);

  static IconData icon(IdeathonStatus status) {
    return switch (status) {
      IdeathonStatus.draft => AppIcons.statusDraft,
      IdeathonStatus.scheduled => AppIcons.clock,
      IdeathonStatus.inProgress => AppIcons.workflowInProgress,
      IdeathonStatus.completed => AppIcons.workflowApproved,
      IdeathonStatus.archived => AppIcons.workflowArchived,
    };
  }

  /// Compact event schedule for banners and grouping headers.
  static String scheduleLabel(DateTime start, DateTime end) {
    final DateTime localStart = start.toLocal();
    final DateTime localEnd = end.toLocal();
    final bool sameDay = localStart.year == localEnd.year &&
        localStart.month == localEnd.month &&
        localStart.day == localEnd.day;
    final String datePart = sameDay
        ? _shortDate(localStart)
        : '${_shortDate(localStart)} – ${_shortDate(localEnd)}';
    return '$datePart · ${_shortTime(localStart)} – ${_shortTime(localEnd)}';
  }

  static String _shortDate(DateTime d) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  static String _shortTime(DateTime d) {
    final int hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String minute = d.minute.toString().padLeft(2, '0');
    final String suffix = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
