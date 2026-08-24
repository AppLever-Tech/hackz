import 'package:flutter/material.dart';

/// One tab/module in the reusable Event Details page.
class EventDetailsModule {
  const EventDetailsModule({
    required this.id,
    required this.label,
    required this.child,
    this.count,
  });

  final String id;
  final String label;
  final Widget child;
  final int? count;
}
