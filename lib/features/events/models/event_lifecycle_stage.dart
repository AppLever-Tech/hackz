import 'package:flutter/material.dart';

/// One stage in a reusable event lifecycle strip.
class EventLifecycleStage {
  const EventLifecycleStage({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

/// A timestamped event for the informational lifecycle timeline.
class EventLifecycleMoment {
  const EventLifecycleMoment({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.at,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime? at;
}
