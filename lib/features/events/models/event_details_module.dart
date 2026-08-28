import 'package:flutter/material.dart';

/// One leaf destination in Event Details (Overview, Judge Assignments, …).
class EventDetailsModule {
  const EventDetailsModule({
    required this.id,
    required this.label,
    required this.child,
    this.count,
    this.icon,
  });

  final String id;
  final String label;
  final Widget child;
  final int? count;
  final IconData? icon;
}

/// Top-level Event Details navigation node.
///
/// A single [items] entry is a peer tab. Multiple entries are grouped
/// navigation (Evaluation, Outcome) — not extra top-level tabs.
class EventDetailsNavGroup {
  const EventDetailsNavGroup({
    required this.id,
    required this.label,
    required this.items,
    this.icon,
  });

  final String id;
  final String label;
  final IconData? icon;
  final List<EventDetailsModule> items;

  bool get isGroup => items.length > 1;
}

/// Lifecycle-adaptive primary command for the event header.
class EventDetailsCommand {
  const EventDetailsCommand({
    required this.label,
    required this.icon,
    this.destinationId,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final String? destinationId;
  final bool enabled;
}

extension EventDetailsNavGroupsX on List<EventDetailsNavGroup> {
  List<EventDetailsModule> get leaves =>
      expand((EventDetailsNavGroup g) => g.items).toList(growable: false);

  EventDetailsModule? leafById(String id) {
    for (final EventDetailsModule m in leaves) {
      if (m.id == id) return m;
    }
    return null;
  }
}
