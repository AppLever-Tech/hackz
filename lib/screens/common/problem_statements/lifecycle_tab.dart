import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../constants/status_styles.dart';
import '../../../models/idea_model.dart';
import '../../../utils/common_helpers.dart';
import '../../../workspace/problem/problem_workspace_loader.dart';
import '../dashboard_components.dart';

/// Problem Lifecycle tab for [ProblemStatementDetailsScreen].
class LifecycleTab extends StatelessWidget {
  const LifecycleTab({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final List<_LifecycleEvent> events = _buildEvents(vm);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Problem statement lifecycle',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                '${events.length} event${events.length == 1 ? '' : 's'} tracked',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ...List<Widget>.generate(events.length, (int index) {
                return _LifecycleEventTile(
                  event: events[index],
                  isLast: index == events.length - 1,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  static List<_LifecycleEvent> _buildEvents(ProblemWorkspaceViewModel vm) {
    final List<_LifecycleEvent> events = <_LifecycleEvent>[
      _LifecycleEvent(
        title: 'Problem statement created',
        subtitle: vm.organizationName.trim().isEmpty ? 'Published to catalog' : vm.organizationName.trim(),
        when: vm.problem.createdAt,
        icon: AppIcons.problems,
        color: const Color(0xFF6A38FF),
      ),
      _LifecycleEvent(
        title: vm.problem.isActive ? 'Active in catalog' : 'Marked inactive',
        subtitle: vm.problem.isActive
            ? 'Teams can view and submit innovations'
            : 'New submissions may be restricted',
        when: vm.problem.updatedAt ?? vm.problem.createdAt,
        icon: vm.problem.isActive ? AppIcons.statusApproved : AppIcons.statusInactive,
        color: vm.problem.isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
      ),
    ];

    for (final ProblemIdeaPreview preview in vm.allIdeas) {
      final IdeaModel idea = preview.idea;
      final String ideaTitle = idea.ideaTitle.trim().isEmpty ? 'Untitled idea' : idea.ideaTitle.trim();
      events.add(
        _LifecycleEvent(
          title: 'Innovation submitted',
          subtitle: '$ideaTitle · ${StatusStyles.labelForIdeaStatus(idea.status)}',
          when: idea.createdAt,
          icon: AppIcons.ideas,
          color: StatusStyles.colorForIdeaStatus(idea.status),
        ),
      );
    }

    events.sort((a, b) {
      final DateTime aWhen = a.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bWhen = b.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bWhen.compareTo(aWhen);
    });

    return events;
  }
}

class _LifecycleEvent {
  const _LifecycleEvent({
    required this.title,
    required this.subtitle,
    required this.when,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime? when;
  final IconData icon;
  final Color color;
}

class _LifecycleEventTile extends StatelessWidget {
  const _LifecycleEventTile({
    required this.event,
    required this.isLast,
  });

  final _LifecycleEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: event.color.withValues(alpha: 0.35)),
                ),
                child: Icon(event.icon, size: 15, color: event.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                  ),
                  if (event.when != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      formatDateTime(event.when!),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
