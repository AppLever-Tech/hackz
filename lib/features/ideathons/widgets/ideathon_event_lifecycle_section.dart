import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/common/lifecycle_timeline.dart';
import 'package:hackz/features/dashboard/chrome/dashboard_components.dart';
import 'package:hackz/features/events/models/event_kind.dart';
import 'package:hackz/features/events/models/event_lifecycle.dart';
import 'package:hackz/features/events/models/event_lifecycle_stage.dart';
import 'package:hackz/features/events/widgets/event_detail_section.dart';
import 'package:hackz/features/events/widgets/event_lifecycle_strip.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_status_helpers.dart';
import 'package:hackz/utils/common_helpers.dart';

/// Event lifecycle strip (always visible) + collapsible vertical timeline.
class IdeathonEventLifecycleSection extends StatefulWidget {
  const IdeathonEventLifecycleSection({super.key, required this.vm});

  final IdeathonDetailsViewModel vm;

  @override
  State<IdeathonEventLifecycleSection> createState() => _IdeathonEventLifecycleSectionState();
}

class _IdeathonEventLifecycleSectionState extends State<IdeathonEventLifecycleSection> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.vm.ideathon;
    final EventKind kind = event.eventKind;
    final EventLifecycleProgress progress = widget.vm.workspace.lifecycleProgress;
    final String currentId = EventLifecycle.currentStageId(progress, usesWinners: kind.usesWinners);
    final int pending = progress.pendingEvaluationCount;
    final String entry = kind.payableItemLabel.toLowerCase();

    final List<EventLifecycleMoment> moments = <EventLifecycleMoment>[
      EventLifecycleMoment(
        title: '${kind.label} created',
        subtitle: 'Event record saved. Judge assignment is the next operational step and is not automatic.',
        at: event.createdAt,
        icon: kind.icon,
        color: const Color(0xFF4F46E5),
      ),
      EventLifecycleMoment(
        title: progress.hasAssignments ? 'Judge assignment started' : 'Judge assignment pending',
        subtitle: progress.hasAssignments
            ? '${widget.vm.workspace.assignmentCount} explicit $entry → judge assignment${widget.vm.workspace.assignmentCount == 1 ? '' : 's'}'
            : 'Optional at first — assign paid ${kind.entriesLabel.toLowerCase()} to judges from Judge Assignments',
        at: widget.vm.workspace.firstAssignedAt,
        icon: AppIcons.judges,
        color: const Color(0xFF7C3AED),
      ),
      EventLifecycleMoment(
        title: event.scheduleType.isEvaluationEvent ? 'Submission / evaluation period' : 'Event schedule',
        subtitle: '${formatDateTime(event.startDateTime.toLocal())} – ${formatDateTime(event.endDateTime.toLocal())}'
            '${progress.scheduleEnded && !progress.completed ? ' · ended (does not complete the event)' : ''}',
        at: event.startDateTime,
        icon: AppIcons.event,
        color: const Color(0xFF0284C7),
      ),
      EventLifecycleMoment(
        title: progress.evaluationStarted ? 'Evaluation began' : 'Evaluation not started',
        subtitle: progress.evaluationStarted
            ? (progress.resultsReady
                ? 'Results ready · ${widget.vm.workspace.evaluationProgressLabel}'
                : pending > 0
                    ? '$pending evaluation${pending == 1 ? '' : 's'} pending · ${widget.vm.workspace.evaluationProgressLabel}'
                    : widget.vm.workspace.evaluationProgressLabel)
            : 'Locking uses the first submitted evaluation, not the scheduled date alone',
        at: widget.vm.workspace.evaluationStartedAt,
        icon: AppIcons.scoring,
        color: const Color(0xFFEA580C),
      ),
      if (event.resultsReviewedAt != null)
        EventLifecycleMoment(
          title: 'Results reviewed',
          subtitle: 'Department Admin reviewed evaluation results',
          at: event.resultsReviewedAt,
          icon: AppIcons.results,
          color: const Color(0xFF059669),
        ),
      if (kind.usesWinners && progress.winnersSelected)
        EventLifecycleMoment(
          title: 'Winners selected',
          subtitle: 'Department Admin selected the official winner'
              '${event.runnerUpIdeaId.trim().isEmpty ? '' : ' and runner-up'}',
          at: event.updatedAt,
          icon: AppIcons.leaderboard,
          color: const Color(0xFFB45309),
        ),
      EventLifecycleMoment(
        title: IdeathonStatusHelpers.label(event.status),
        subtitle: progress.completed
            ? (kind.usesWinners
                ? 'Event completed · evaluations, assignments, template, and winners are locked'
                : 'Event completed · evaluations, assignments, and template are locked')
            : 'Current stored lifecycle status',
        at: event.updatedAt,
        icon: IdeathonStatusHelpers.icon(event.status),
        color: IdeathonStatusHelpers.color(event.status),
      ),
    ]..sort((EventLifecycleMoment a, EventLifecycleMoment b) {
        final DateTime aAt = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bAt = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bAt.compareTo(aAt);
      });

    return EventDetailSection(
      title: 'Event lifecycle',
      icon: AppIcons.checklist,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EventLifecycleStrip(stages: EventLifecycle.stagesFor(kind), currentId: currentId),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  Text(
                    _detailsExpanded ? 'Hide details' : 'Show details',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _detailsExpanded ? AppIcons.expandLess : AppIcons.expandMore,
                    size: 18,
                    color: const Color(0xFF4F46E5),
                  ),
                ],
              ),
            ),
          ),
          if (_detailsExpanded) ...<Widget>[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: kDashboardCardDecoration,
              child: LifecycleTimeline(
                title: 'Timeline',
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
        ],
      ),
    );
  }
}
