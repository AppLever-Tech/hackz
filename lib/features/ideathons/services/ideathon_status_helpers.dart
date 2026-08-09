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
}
