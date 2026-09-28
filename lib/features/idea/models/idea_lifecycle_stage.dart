import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'enums/idea_status.dart';

/// Idea-only lifecycle stages. Event payment, evaluation, and winners are not included.
enum IdeaLifecycleStage {
  created,
  submitted,
  active;

  String get label => switch (this) {
        IdeaLifecycleStage.created => 'Idea Created',
        IdeaLifecycleStage.submitted => 'Idea Submitted',
        IdeaLifecycleStage.active => 'Active',
      };

  IconData get icon => switch (this) {
        IdeaLifecycleStage.created => AppIcons.statusDraft,
        IdeaLifecycleStage.submitted => AppIcons.statusSubmitted,
        IdeaLifecycleStage.active => AppIcons.statusActive,
      };

  Color get color => switch (this) {
        IdeaLifecycleStage.created => const Color(0xFF64748B),
        IdeaLifecycleStage.submitted => const Color(0xFF0EA5E9),
        IdeaLifecycleStage.active => const Color(0xFF059669),
      };

  Color get background => color.withValues(alpha: 0.12);

  /// Draft ideas sit on Created; submitted ideas are Active.
  static IdeaLifecycleStage currentFor(IdeaStatus status) {
    return status == IdeaStatus.submitted ? IdeaLifecycleStage.active : IdeaLifecycleStage.created;
  }

  static const List<IdeaLifecycleStage> displayOrder = <IdeaLifecycleStage>[
    IdeaLifecycleStage.created,
    IdeaLifecycleStage.submitted,
    IdeaLifecycleStage.active,
  ];
}
