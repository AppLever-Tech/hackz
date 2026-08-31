import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/events/models/event_lifecycle.dart';
import 'package:hackz/features/events/models/event_lifecycle_stage.dart';
import 'package:hackz/features/events/widgets/event_lifecycle_section.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_status_helpers.dart';
import 'package:hackz/utils/common_helpers.dart';

class IdeathonLifecycleTab extends StatelessWidget {
  const IdeathonLifecycleTab({super.key, required this.vm, this.embedded = false});

  final IdeathonDetailsViewModel vm;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final event = vm.ideathon;
    final EventLifecycleProgress progress = vm.workspace.lifecycleProgress;
    final String currentId = EventLifecycle.currentStageId(progress);
    final int pending = progress.pendingEvaluationCount;

    final List<EventLifecycleMoment> moments = <EventLifecycleMoment>[
      EventLifecycleMoment(
        title: 'Ideathon created',
        subtitle: 'Event record saved. Judge assignment is the next operational step and is not automatic.',
        at: event.createdAt,
        icon: AppIcons.ideathons,
        color: const Color(0xFF4F46E5),
      ),
      EventLifecycleMoment(
        title: progress.hasAssignments ? 'Judge assignment started' : 'Judge assignment pending',
        subtitle: progress.hasAssignments
            ? '${vm.workspace.assignmentCount} explicit idea → judge assignment${vm.workspace.assignmentCount == 1 ? '' : 's'}'
            : 'Optional at first — assign paid ideas to judges from Judge Assignments',
        at: vm.workspace.firstAssignedAt,
        icon: AppIcons.judges,
        color: const Color(0xFF7C3AED),
      ),
      EventLifecycleMoment(
        title: 'Scheduled window',
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
                ? 'Results ready · ${vm.workspace.evaluationProgressLabel}'
                : pending > 0
                    ? '$pending evaluation${pending == 1 ? '' : 's'} pending · ${vm.workspace.evaluationProgressLabel}'
                    : vm.workspace.evaluationProgressLabel)
            : 'Locking uses the first submitted evaluation, not the scheduled date alone',
        at: vm.workspace.evaluationStartedAt,
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
      if (progress.winnersSelected)
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
            ? 'Event completed · evaluations, assignments, template, and winners are locked'
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

    return EventLifecycleSection(
      stages: EventLifecycle.standardStages(),
      currentId: currentId,
      moments: moments,
      embedded: embedded,
    );
  }
}
