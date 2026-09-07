import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// Shared event kinds that use the Event Details framework.
enum EventKind {
  ideathon,
  hackathon,
  researchPaper;

  String get label => switch (this) {
        EventKind.ideathon => 'Ideathon',
        EventKind.hackathon => 'Hackathon',
        EventKind.researchPaper => 'Research Paper',
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
        EventKind.researchPaper => 'Research Papers',
      };

  IconData get entriesIcon => switch (this) {
        EventKind.ideathon => AppIcons.ideas,
        EventKind.hackathon => AppIcons.submissions,
        EventKind.researchPaper => AppIcons.researchPapers,
      };

  /// Singular payable item for event payment copy (Idea vs Prototype vs Research Paper).
  String get payableItemLabel => switch (this) {
        EventKind.ideathon => 'Idea',
        EventKind.hackathon => 'Prototype',
        EventKind.researchPaper => 'Research Paper',
      };

  String get helpPageId => switch (this) {
        EventKind.ideathon => 'ideathon',
        EventKind.hackathon => 'hackathon',
        EventKind.researchPaper => 'ideathon',
      };

  bool get usesWinners => this == EventKind.ideathon;

  bool get usesIdeaPayments => this == EventKind.ideathon || this == EventKind.researchPaper;

  /// Long-running evaluation container (not a same-day event).
  bool get isLongRunning => this == EventKind.researchPaper;

  String get wireValue => name;

  static EventKind fromWire(Object? value) {
    final String v = (value as String? ?? '').trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return switch (v) {
      'hackathon' => EventKind.hackathon,
      'researchpaper' => EventKind.researchPaper,
      _ => EventKind.ideathon,
    };
  }

  /// Default Research Paper window: six months after [start].
  static DateTime defaultEndDateTime(DateTime start) {
    return DateTime(start.year, start.month + 6, start.day, start.hour, start.minute);
  }
}
