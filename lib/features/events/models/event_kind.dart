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
        EventKind.hackathon => 'Entries',
      };

  String get helpPageId => switch (this) {
        EventKind.ideathon => 'ideathon',
        EventKind.hackathon => 'hackathon',
      };
}
