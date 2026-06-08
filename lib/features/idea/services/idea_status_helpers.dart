import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/enums/idea_status.dart';

/// Labels, colors, icons, and lifecycle helpers for [IdeaStatus].
abstract final class IdeaStatusHelpers {
  IdeaStatusHelpers._();

  static String label(IdeaStatus status) {
    return switch (status) {
      IdeaStatus.draft => 'Draft',
      IdeaStatus.submitted => 'Submitted',
      IdeaStatus.underEvaluation => 'Under Evaluation',
      IdeaStatus.evaluated => 'Evaluated',
      IdeaStatus.shortlisted => 'Shortlisted',
      IdeaStatus.rejected => 'Rejected',
      IdeaStatus.eventAssigned => 'Event Assigned',
      IdeaStatus.winner => 'Winner',
      IdeaStatus.archived => 'Archived',
    };
  }

  static Color color(IdeaStatus status) {
    return switch (status) {
      IdeaStatus.draft => const Color(0xFF64748B),
      IdeaStatus.submitted => const Color(0xFF9E9E9E),
      IdeaStatus.underEvaluation => const Color(0xFF1E88E5),
      IdeaStatus.evaluated => const Color(0xFF7B1FA2),
      IdeaStatus.shortlisted => const Color(0xFF2E7D32),
      IdeaStatus.rejected => const Color(0xFFC62828),
      IdeaStatus.eventAssigned => const Color(0xFF0EA5E9),
      IdeaStatus.winner => const Color(0xFFD97706),
      IdeaStatus.archived => const Color(0xFF94A3B8),
    };
  }

  static Color background(IdeaStatus status) {
    return color(status).withValues(alpha: 0.12);
  }

  static IconData icon(IdeaStatus status) => AppIcons.forIdeaStatus(status);

  static bool isPostEvaluationReview(IdeaStatus status) {
    return status == IdeaStatus.evaluated ||
        status == IdeaStatus.shortlisted ||
        status == IdeaStatus.rejected;
  }

  static bool canShortlistFrom(IdeaStatus status) => status == IdeaStatus.evaluated;

  static bool canRejectFrom(IdeaStatus status) => status == IdeaStatus.evaluated;

  static int lifecycleIndex(IdeaStatus status) {
    final int idx = IdeaStatus.lifecycleOrder.indexOf(status);
    if (idx >= 0) return idx;
    if (status == IdeaStatus.rejected) {
      return IdeaStatus.lifecycleOrder.indexOf(IdeaStatus.evaluated);
    }
    return -1;
  }

  static bool isLifecycleComplete(IdeaStatus status, IdeaStatus stage) {
    final int current = lifecycleIndex(status);
    final int target = IdeaStatus.lifecycleOrder.indexOf(stage);
    if (current < 0 || target < 0) return false;
    return current > target;
  }

  static bool isLifecycleCurrent(IdeaStatus status, IdeaStatus stage) {
    if (status == IdeaStatus.rejected && stage == IdeaStatus.evaluated) return true;
    return status == stage;
  }
}
