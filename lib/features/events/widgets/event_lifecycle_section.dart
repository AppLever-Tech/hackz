import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/lifecycle_timeline.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../models/event_lifecycle_stage.dart';
import 'event_lifecycle_strip.dart';

/// Informational lifecycle tab for Event Details.
class EventLifecycleSection extends StatelessWidget {
  const EventLifecycleSection({
    super.key,
    required this.stages,
    required this.currentId,
    required this.moments,
    this.title = 'Event lifecycle',
  });

  final List<EventLifecycleStage> stages;
  final String currentId;
  final List<EventLifecycleMoment> moments;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: EventLifecycleStrip(stages: stages, currentId: currentId),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: LifecycleTimeline(
            title: title,
            subtitle: '${moments.length} event${moments.length == 1 ? '' : 's'} tracked',
            events: moments
                .map(
                  (EventLifecycleMoment m) => LifecycleTimelineEvent(
                    title: m.title,
                    subtitle: m.subtitle,
                    when: m.at,
                    icon: m.icon,
                    color: m.color,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

/// Compact participation row for Event Ideas/Entries.
class EventEntryRow extends StatelessWidget {
  const EventEntryRow({
    super.key,
    required this.ideaLabel,
    required this.onIdeaTap,
    required this.status,
    this.problemLabel = '',
    this.onProblemTap,
    this.teamLabel = '',
    this.onTeamTap,
  });

  final String ideaLabel;
  final VoidCallback onIdeaTap;
  final Widget status;
  final String problemLabel;
  final VoidCallback? onProblemTap;
  final String teamLabel;
  final VoidCallback? onTeamTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ContextPill(
                    label: ideaLabel,
                    semantic: ContextPillSemantic.idea,
                    icon: AppIcons.ideas,
                    onTap: onIdeaTap,
                    compact: true,
                    fitContent: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              status,
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (problemLabel.trim().isNotEmpty)
                ContextPill(
                  label: problemLabel,
                  semantic: ContextPillSemantic.problem,
                  onTap: onProblemTap ?? () {},
                  enabled: onProblemTap != null,
                  compact: true,
                  fitContent: true,
                ),
              if (teamLabel.trim().isNotEmpty)
                ContextPill(
                  label: teamLabel,
                  semantic: ContextPillSemantic.team,
                  onTap: onTeamTap ?? () {},
                  enabled: onTeamTap != null,
                  compact: true,
                  fitContent: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
