import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/enums/idea_status.dart';

/// Labels, colors, icons, and lifecycle helpers for [IdeaStatus].
abstract final class IdeaStatusHelpers {
  IdeaStatusHelpers._();

  static String label(IdeaStatus status) {
    return switch (status) {
      IdeaStatus.draft => 'Draft',
      IdeaStatus.submitted => 'Submitted',
    };
  }

  static Color color(IdeaStatus status) {
    return switch (status) {
      IdeaStatus.draft => const Color(0xFF64748B),
      IdeaStatus.submitted => const Color(0xFF0EA5E9),
    };
  }

  static Color background(IdeaStatus status) {
    return color(status).withValues(alpha: 0.12);
  }

  static IconData icon(IdeaStatus status) => AppIcons.forIdeaStatus(status);

  /// Submitted ideas can be added to an Ideathon.
  static bool isEligibleForIdeathon(IdeaStatus status) => status == IdeaStatus.submitted;

  static int lifecycleIndex(IdeaStatus status) => IdeaStatus.lifecycleOrder.indexOf(status);

  static bool isLifecycleComplete(IdeaStatus status, IdeaStatus stage) {
    final int current = lifecycleIndex(status);
    final int target = IdeaStatus.lifecycleOrder.indexOf(stage);
    if (current < 0 || target < 0) return false;
    return current > target;
  }

  static bool isLifecycleCurrent(IdeaStatus status, IdeaStatus stage) => status == stage;
}
