import 'package:flutter/material.dart';

import '../../../../constants/app_icons.dart';
import '../../../../constants/status_styles.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../../../screens/common/dashboard_components.dart';
import '../../../../shared/widgets/lifecycle_timeline.dart';
import '../../models/problem_status.dart';
import '../../services/problem_status_helpers.dart';
import '../../widgets/problem_lifecycle_strip.dart';
import '../../workspace/problem_workspace_loader.dart';

/// Problem Lifecycle tab for [ProblemStatementDetailsScreen].
class LifecycleTab extends StatelessWidget {
  const LifecycleTab({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final List<LifecycleTimelineEvent> events = _buildEvents(vm);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: ProblemLifecycleStrip(currentStatus: vm.problem.status),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: LifecycleTimeline(
            title: 'Problem statement lifecycle',
            subtitle: '${events.length} event${events.length == 1 ? '' : 's'} tracked',
            events: events,
          ),
        ),
      ],
    );
  }

  static List<LifecycleTimelineEvent> _buildEvents(ProblemWorkspaceViewModel vm) {
    final ProblemStatus status = vm.problem.status;
    final List<LifecycleTimelineEvent> events = <LifecycleTimelineEvent>[
      LifecycleTimelineEvent(
        title: 'Problem statement created',
        subtitle: vm.organizationName.trim().isEmpty ? 'Published to catalog' : vm.organizationName.trim(),
        when: vm.problem.createdAt,
        icon: AppIcons.problems,
        color: const Color(0xFF6A38FF),
      ),
      LifecycleTimelineEvent(
        title: ProblemStatusHelpers.label(status),
        subtitle: _statusSubtitle(status),
        when: vm.problem.updatedAt ?? vm.problem.createdAt,
        icon: ProblemStatusHelpers.icon(status),
        color: ProblemStatusHelpers.color(status),
      ),
    ];

    for (final ProblemIdeaPreview preview in vm.allIdeas) {
      final IdeaModel idea = preview.idea;
      final String ideaTitle = idea.ideaTitle.trim().isEmpty ? 'Untitled idea' : idea.ideaTitle.trim();
      events.add(
        LifecycleTimelineEvent(
          title: 'Innovation submitted',
          subtitle: '$ideaTitle · ${StatusStyles.labelForIdeaStatus(idea.status)}',
          when: idea.createdAt,
          icon: AppIcons.ideas,
          color: StatusStyles.colorForIdeaStatus(idea.status),
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

  static String _statusSubtitle(ProblemStatus status) {
    return switch (status) {
      ProblemStatus.draft => 'Awaiting review before activation',
      ProblemStatus.active => 'Teams can view and submit innovations',
      ProblemStatus.inactive => 'New submissions may be restricted',
      ProblemStatus.archived => 'Removed from active catalog',
    };
  }
}
