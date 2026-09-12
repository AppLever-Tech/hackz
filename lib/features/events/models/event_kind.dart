import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'event_schedule_type.dart';

/// Event template on the shared event document. Presentation and defaults only —
/// Ideathon, Hackathon, and Research Paper share one event/submission model.
enum EventKind {
  ideathon,
  hackathon,
  researchPaper;

  String get label => switch (this) {
        EventKind.ideathon => 'Ideathon',
        EventKind.hackathon => 'Hackathon',
        EventKind.researchPaper => 'Research Paper',
      };

  /// Create-event picker label.
  String get templateLabel => switch (this) {
        EventKind.researchPaper => 'Research Papers',
        _ => label,
      };

  String get listLabel => switch (this) {
        EventKind.ideathon => 'Ideathons',
        EventKind.hackathon => 'Hackathons',
        EventKind.researchPaper => 'Research Papers',
      };

  IconData get icon => switch (this) {
        EventKind.ideathon => AppIcons.ideathons,
        EventKind.hackathon => AppIcons.event,
        EventKind.researchPaper => AppIcons.researchPapers,
      };

  String get entriesLabel => switch (this) {
        EventKind.ideathon => 'Ideas',
        EventKind.hackathon => 'Prototypes',
        EventKind.researchPaper => 'Papers',
      };

  IconData get entriesIcon => switch (this) {
        EventKind.ideathon => AppIcons.ideas,
        EventKind.hackathon => AppIcons.submissions,
        EventKind.researchPaper => AppIcons.researchPapers,
      };

  /// Singular payable item for event payment copy (Idea vs Prototype vs Paper).
  String get payableItemLabel => switch (this) {
        EventKind.ideathon => 'Idea',
        EventKind.hackathon => 'Prototype',
        EventKind.researchPaper => 'Paper',
      };

  String get helpPageId => switch (this) {
        EventKind.ideathon => 'ideathon',
        EventKind.hackathon => 'hackathon',
        EventKind.researchPaper => 'ideathon',
      };

  bool get usesWinners => this == EventKind.ideathon;

  bool get usesIdeaPayments => this == EventKind.ideathon || this == EventKind.researchPaper;

  EventScheduleType get defaultScheduleType => switch (this) {
        EventKind.researchPaper => EventScheduleType.evaluationEvent,
        _ => EventScheduleType.dayEvent,
      };

  /// Default schedule for this template. Prefer [IdeathonModel.scheduleType] on saved events.
  bool get isLongRunning => defaultScheduleType.isEvaluationEvent;

  String defaultEventName([int? year]) {
    final int y = year ?? DateTime.now().year;
    return switch (this) {
      EventKind.ideathon => 'Ideathon $y',
      EventKind.hackathon => 'Hackathon $y',
      EventKind.researchPaper => 'Research Paper Evaluation $y',
    };
  }

  String get wireValue => name;

  static EventKind fromWire(Object? value) {
    final String v = (value as String? ?? '').trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return switch (v) {
      'hackathon' => EventKind.hackathon,
      'researchpaper' => EventKind.researchPaper,
      _ => EventKind.ideathon,
    };
  }

  /// Default Research Paper / evaluation-event window: six months after [start].
  static DateTime defaultEndDateTime(DateTime start) {
    return EventScheduleType.evaluationEvent.defaultEndDateTime(start);
  }
}
