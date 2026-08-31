import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'event_lifecycle_stage.dart';

/// Shared event-lifecycle stage ids (Ideathon today; Hackathon later).
abstract final class EventLifecycleStageId {
  EventLifecycleStageId._();

  static const String created = 'created';
  static const String assignment = 'assignment';
  static const String preparation = 'preparation';
  static const String started = 'started';
  static const String evaluation = 'evaluation';
  static const String resultsReady = 'results';
  static const String winners = 'winners';
  static const String completed = 'completed';
}

/// Inputs for resolving the current event phase. Schedule drives phase; it does
/// not auto-complete the event.
class EventLifecycleProgress {
  const EventLifecycleProgress({
    required this.hasAssignments,
    required this.startDateTime,
    required this.endDateTime,
    required this.evaluationStarted,
    required this.completedEvaluationCount,
    required this.totalEvaluationCount,
    required this.resultsReviewed,
    required this.winnersSelected,
    required this.completed,
  });

  final bool hasAssignments;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool evaluationStarted;
  final int completedEvaluationCount;
  final int totalEvaluationCount;
  final bool resultsReviewed;
  final bool winnersSelected;
  final bool completed;

  bool get eventStarted => !DateTime.now().isBefore(startDateTime);

  /// Informational only — never auto-completes the event.
  bool get scheduleEnded => DateTime.now().isAfter(endDateTime);

  int get pendingEvaluationCount {
    final int pending = totalEvaluationCount - completedEvaluationCount;
    return pending < 0 ? 0 : pending;
  }

  bool get resultsReady =>
      totalEvaluationCount > 0 && completedEvaluationCount >= totalEvaluationCount;
}

/// One contextual primary action for Event Details.
enum EventPrimaryActionKind {
  manageAssignments,
  evaluationInProgress,
  reviewResults,
  selectWinners,
  completeEvent,
  viewResults,
  viewWinners,
}

/// Resolves strip stage + primary action from [EventLifecycleProgress].
abstract final class EventLifecycle {
  EventLifecycle._();

  static List<EventLifecycleStage> standardStages() {
    return const <EventLifecycleStage>[
      EventLifecycleStage(
        id: EventLifecycleStageId.created,
        label: 'Created',
        icon: AppIcons.event,
        color: Color(0xFF4F46E5),
      ),
      EventLifecycleStage(
        id: EventLifecycleStageId.assignment,
        label: 'Judge Assignment',
        icon: AppIcons.judges,
        color: Color(0xFF7C3AED),
      ),
      EventLifecycleStage(
        id: EventLifecycleStageId.preparation,
        label: 'Preparation',
        icon: AppIcons.checklist,
        color: Color(0xFF0284C7),
      ),
      EventLifecycleStage(
        id: EventLifecycleStageId.started,
        label: 'Event Started',
        icon: AppIcons.event,
        color: Color(0xFF0EA5E9),
      ),
      EventLifecycleStage(
        id: EventLifecycleStageId.evaluation,
        label: 'Evaluation',
        icon: AppIcons.scoring,
        color: Color(0xFFEA580C),
      ),
      EventLifecycleStage(
        id: EventLifecycleStageId.resultsReady,
        label: 'Results Ready',
        icon: AppIcons.results,
        color: Color(0xFF059669),
      ),
      EventLifecycleStage(
        id: EventLifecycleStageId.winners,
        label: 'Winners',
        icon: AppIcons.leaderboard,
        color: Color(0xFFB45309),
      ),
      EventLifecycleStage(
        id: EventLifecycleStageId.completed,
        label: 'Completed',
        icon: AppIcons.workflowApproved,
        color: Color(0xFF047857),
      ),
    ];
  }

  static String currentStageId(EventLifecycleProgress progress) {
    if (progress.completed) return EventLifecycleStageId.completed;
    if (progress.winnersSelected) return EventLifecycleStageId.winners;
    if (progress.resultsReady) return EventLifecycleStageId.resultsReady;
    if (progress.evaluationStarted) return EventLifecycleStageId.evaluation;
    if (progress.eventStarted) return EventLifecycleStageId.started;
    if (progress.hasAssignments) return EventLifecycleStageId.preparation;
    return EventLifecycleStageId.created;
  }

  /// [canManageOutcome] is Department Admin (select winners / complete event).
  static EventPrimaryActionKind primaryAction(
    EventLifecycleProgress progress, {
    required bool canManageOutcome,
  }) {
    if (progress.completed) {
      return canManageOutcome
          ? EventPrimaryActionKind.viewWinners
          : EventPrimaryActionKind.viewResults;
    }
    if (canManageOutcome && progress.winnersSelected) {
      return EventPrimaryActionKind.completeEvent;
    }
    if (progress.winnersSelected) return EventPrimaryActionKind.viewResults;
    if (canManageOutcome && progress.resultsReady && progress.resultsReviewed) {
      return EventPrimaryActionKind.selectWinners;
    }
    if (progress.resultsReady) return EventPrimaryActionKind.reviewResults;
    if (progress.evaluationStarted) return EventPrimaryActionKind.evaluationInProgress;
    return EventPrimaryActionKind.manageAssignments;
  }
}
