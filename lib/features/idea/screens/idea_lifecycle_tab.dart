import 'package:flutter/material.dart';

import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../core/ui/common/lifecycle_timeline.dart';
import '../models/enums/idea_status.dart';
import '../models/idea_lifecycle_stage.dart';
import '../widgets/idea_lifecycle_strip.dart';
import '../workspace/idea_workspace_loader.dart';

/// Idea Lifecycle tab for [IdeaDetailsPane].
class IdeaLifecycleTab extends StatelessWidget {
  const IdeaLifecycleTab({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents(vm);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: IdeaLifecycleStrip(currentStatus: vm.idea.status),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: LifecycleTimeline(
            title: 'Idea lifecycle',
            subtitle: '${events.length} event${events.length == 1 ? '' : 's'} tracked',
            events: events,
          ),
        ),
      ],
    );
  }

  static List<LifecycleTimelineEvent> _buildEvents(IdeaWorkspaceViewModel vm) {
    final idea = vm.idea;
    final List<LifecycleTimelineEvent> events = <LifecycleTimelineEvent>[
      LifecycleTimelineEvent(
        title: IdeaLifecycleStage.created.label,
        subtitle: idea.ideaTitle.trim().isEmpty ? 'Idea recorded' : idea.ideaTitle.trim(),
        when: idea.createdAt,
        icon: IdeaLifecycleStage.created.icon,
        color: IdeaLifecycleStage.created.color,
      ),
    ];

    if (idea.status == IdeaStatus.submitted) {
      events.add(
        LifecycleTimelineEvent(
          title: IdeaLifecycleStage.submitted.label,
          subtitle: 'Idea locked for editing',
          when: idea.createdAt,
          icon: IdeaLifecycleStage.submitted.icon,
          color: IdeaLifecycleStage.submitted.color,
        ),
      );
      events.add(
        LifecycleTimelineEvent(
          title: IdeaLifecycleStage.active.label,
          subtitle: 'Idea is active',
          when: idea.createdAt,
          icon: IdeaLifecycleStage.active.icon,
          color: IdeaLifecycleStage.active.color,
        ),
      );
    }

    events.sort((LifecycleTimelineEvent a, LifecycleTimelineEvent b) {
      final DateTime aWhen = a.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bWhen = b.when ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bWhen.compareTo(aWhen);
    });

    return events;
  }
}
