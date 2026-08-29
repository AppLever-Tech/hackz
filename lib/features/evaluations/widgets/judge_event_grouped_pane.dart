import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../ideathons/models/ideathon_status.dart';
import 'judge_event_grouping.dart';
import 'judge_evaluation_event_header.dart';

/// Scrollable list of event sections used by Pending, Evaluated, and Feedback.
class JudgeEventGroupedPane<T> extends StatefulWidget {
  const JudgeEventGroupedPane({
    super.key,
    required this.items,
    required this.eventIdOf,
    required this.nameOf,
    required this.scheduleOf,
    required this.sectionChild,
    required this.empty,
    this.statusOf,
    this.startAtOf,
    this.activityAtOf,
    this.pendingCountByEvent = const <String, int>{},
    this.evaluatedCountByEvent = const <String, int>{},
    this.sort = JudgeEventGroupSort.statusThenName,
    this.collapsible = false,
  });

  final List<T> items;
  final String Function(T) eventIdOf;
  final String Function(T) nameOf;
  final String Function(T) scheduleOf;
  final IdeathonStatus? Function(T)? statusOf;
  final DateTime? Function(T)? startAtOf;
  final DateTime? Function(T)? activityAtOf;
  final Map<String, int> pendingCountByEvent;
  final Map<String, int> evaluatedCountByEvent;
  final JudgeEventGroupSort sort;
  final bool collapsible;
  final Widget Function(List<T> group) sectionChild;
  final Widget empty;

  @override
  State<JudgeEventGroupedPane<T>> createState() => _JudgeEventGroupedPaneState<T>();
}

class _JudgeEventGroupedPaneState<T> extends State<JudgeEventGroupedPane<T>> {
  final Set<String> _expandedIds = <String>{};
  bool _userInteracted = false;

  @override
  void initState() {
    super.initState();
    _seedIfNeeded();
  }

  @override
  void didUpdateWidget(covariant JudgeEventGroupedPane<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _seedIfNeeded();
  }

  List<MapEntry<JudgeEventSection, List<T>>> _groups() {
    return JudgeEventGrouping.group<T>(
      items: widget.items,
      eventIdOf: widget.eventIdOf,
      nameOf: widget.nameOf,
      scheduleOf: widget.scheduleOf,
      statusOf: widget.statusOf,
      startAtOf: widget.startAtOf,
      activityAtOf: widget.activityAtOf,
      pendingCountByEvent: widget.pendingCountByEvent,
      evaluatedCountByEvent: widget.evaluatedCountByEvent,
      sort: widget.sort,
    );
  }

  void _seedIfNeeded() {
    if (widget.items.isEmpty) {
      _expandedIds.clear();
      return;
    }
    final List<MapEntry<JudgeEventSection, List<T>>> groups = _groups();
    final Set<String> present = groups.map((MapEntry<JudgeEventSection, List<T>> g) => g.key.eventId).toSet();
    _expandedIds.removeWhere((String id) => !present.contains(id));
    if (!widget.collapsible || _userInteracted || groups.isEmpty) return;
    _expandedIds
      ..clear()
      ..add(groups.first.key.eventId);
  }

  void _toggle(String eventId) {
    setState(() {
      _userInteracted = true;
      if (_expandedIds.contains(eventId)) {
        _expandedIds.remove(eventId);
      } else {
        _expandedIds.add(eventId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return widget.empty;

    final List<MapEntry<JudgeEventSection, List<T>>> groups = _groups();

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<JudgeEventSection, List<T>> group = groups[index];
        final bool expanded = !widget.collapsible || _expandedIds.contains(group.key.eventId);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            JudgeEvaluationEventHeader(
              section: group.key,
              expanded: expanded,
              onToggle: widget.collapsible ? () => _toggle(group.key.eventId) : null,
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOutCubic,
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: widget.sectionChild(group.value),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shared empty card for scoring tabs.
class JudgeScoringEmptyState extends StatelessWidget {
  const JudgeScoringEmptyState({
    super.key,
    required this.title,
    this.message = 'Assigned event ideas will appear here.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(28),
        decoration: kDashboardCardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(AppIcons.scoring, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
