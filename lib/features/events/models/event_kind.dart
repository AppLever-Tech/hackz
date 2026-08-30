import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// Shared event kinds that use the Event Details framework.
enum EventKind {
  ideathon,
  hackathon;

  String get label => switch (this) {
        EventKind.ideathon => 'Ideathon',
        EventKind.hackathon => 'Hackathon',
      };

  IconData get icon => switch (this) {
        EventKind.ideathon => AppIcons.ideathons,
        EventKind.hackathon => AppIcons.event,
      };

  String get entriesLabel => switch (this) {
        EventKind.ideathon => 'Ideas',
        EventKind.hackathon => 'Prototypes',
      };

  IconData get entriesIcon => switch (this) {
        EventKind.ideathon => AppIcons.ideas,
        EventKind.hackathon => AppIcons.submissions,
      };

  /// Singular payable item for event payment copy (Idea vs Prototype).
  String get payableItemLabel => switch (this) {
        EventKind.ideathon => 'Idea',
        EventKind.hackathon => 'Prototype',
      };

  String get helpPageId => switch (this) {
        EventKind.ideathon => 'ideathon',
        EventKind.hackathon => 'hackathon',
      };
}
