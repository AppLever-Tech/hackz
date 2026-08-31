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
    this.meta,
    this.initiallyExpanded = false,
    this.collapsible = true,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final int? count;
  /// Extra header value after [count] (e.g. total weightage), before the chevron.
  final Widget? meta;
  final bool initiallyExpanded;
  final bool collapsible;

  static const TextStyle countStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1,
    color: Color(0xFF0F172A),
  );

  static const TextStyle metaStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1,
    color: Color(0xFFB45309),
  );

  @override
  State<WorkspaceCollapsibleSection> createState() => _WorkspaceCollapsibleSectionState();
}

class _WorkspaceCollapsibleSectionState extends State<WorkspaceCollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  Widget? _titleSuffix() {
    if (widget.count == null && widget.meta == null) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.count != null)
          Text('${widget.count}', style: WorkspaceCollapsibleSection.countStyle),
        if (widget.count != null && widget.meta != null) const SizedBox(width: 10),
        if (widget.meta != null) widget.meta!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return EventDetailSection(
      title: widget.title,
      icon: widget.icon,
      titleSuffix: _titleSuffix(),
      collapsible: widget.collapsible,
      expanded: widget.collapsible ? _expanded : true,
      onToggle: widget.collapsible ? _toggle : null,
      child: widget.child,
    );
  }
}
