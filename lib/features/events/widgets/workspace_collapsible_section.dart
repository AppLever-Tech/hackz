import 'package:flutter/material.dart';

import 'event_detail_section.dart';

/// Workspace card with icon + title, optional count beside the title, and a collapsible body.
class WorkspaceCollapsibleSection extends StatefulWidget {
  const WorkspaceCollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.count,
    this.initiallyExpanded = false,
    this.collapsible = true,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final int? count;
  final bool initiallyExpanded;
  final bool collapsible;

  static const TextStyle countStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1,
    color: Color(0xFF0F172A),
  );

  @override
  State<WorkspaceCollapsibleSection> createState() => _WorkspaceCollapsibleSectionState();
}

class _WorkspaceCollapsibleSectionState extends State<WorkspaceCollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return EventDetailSection(
      title: widget.title,
      icon: widget.icon,
      titleSuffix: widget.count == null
          ? null
          : Text('${widget.count}', style: WorkspaceCollapsibleSection.countStyle),
      collapsible: widget.collapsible,
      expanded: widget.collapsible ? _expanded : true,
      onToggle: widget.collapsible ? _toggle : null,
      child: widget.child,
    );
  }
}
