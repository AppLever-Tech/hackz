import 'package:flutter/material.dart';

/// One workspace destination on the internal navigation stack.
class WorkspaceRoute {
  const WorkspaceRoute({
    required this.id,
    required this.title,
    required this.builder,
    this.subtitle,
    this.prepare,
  });

  /// Stable key for transitions and stack identity (e.g. `idea:abc123`).
  final String id;
  final String title;
  final String? subtitle;

  /// Builds workspace body below the header.
  final WidgetBuilder builder;

  /// Optional async prep (fetch entity) before [builder] is shown.
  final Future<void> Function()? prepare;
}
