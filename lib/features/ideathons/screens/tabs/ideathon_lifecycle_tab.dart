import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/events/models/event_lifecycle_stage.dart';
import 'package:hackz/features/events/widgets/event_lifecycle_section.dart';
import 'package:hackz/features/ideathons/models/ideathon_status.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_status_helpers.dart';
import 'package:hackz/utils/common_helpers.dart';

class IdeathonLifecycleTab extends StatelessWidget {
  const IdeathonLifecycleTab({super.key, required this.vm, this.embedded = false});

  final IdeathonDetailsViewModel vm;
  final bool embedded;

  static const String _stageCreated = 'created';
  static const String _stageAssignment = 'assignment';
  static const String _stagePrep = 'preparation';
  static const String _stageStarted = 'started';
  static const String _stageEvaluation = 'evaluation';
  static const String _stageResults = 'results';
  static const String _stageWinners = 'winners';

  @override
  Widget build(BuildContext context) {
    final event = vm.ideathon;
    final bool evaluationStarted = vm.workspace.evaluationStarted;
    final bool hasAssignments = vm.workspace.assignmentCount > 0;
    final bool eventStarted = DateTime.now().isAfter(event.startDateTime);
    final bool completed = event.status == IdeathonStatus.completed || event.status == IdeathonStatus.archived;

    final List<EventLifecycleStage> stages = <EventLifecycleStage>[
      EventLifecycleStage(id: _stageCreated, label: 'Created', icon: AppIcons.ideathons, color: const Color(0xFF4F46E5)),
      EventLifecycleStage(id: _stageAssignment, label: 'Judge Assignment', icon: AppIcons.judges, color: const Color(0xFF7C3AED)),
      EventLifecycleStage(id: _stagePrep, label: 'Preparation', icon: AppIcons.checklist, color: const Color(0xFF0284C7)),
      EventLifecycleStage(id: _stageStarted, label: 'Event Started', icon: AppIcons.event, color: const Color(0xFF0EA5E9)),
      EventLifecycleStage(id: _stageEvaluation, label: 'Evaluation', icon: AppIcons.scoring, color: const Color(0xFFEA580C)),
      EventLifecycleStage(id: _stageResults, label: 'Results', icon: AppIcons.results, color: const Color(0xFF059669)),
      EventLifecycleStage(id: _stageWinners, label: 'Winners', icon: AppIcons.leaderboard, color: const Color(0xFFB45309)),
    ];

    String currentId = _stageCreated;
    if (completed) {
      currentId = _stageWinners;
    } else if (evaluationStarted) {
      currentId = vm.workspace.evaluationProgressPct >= 1 ? _stageResults : _stageEvaluation;
    } else if (eventStarted) {
      currentId = _stageStarted;
    } else if (hasAssignments) {
      currentId = _stagePrep;
    }

    final List<EventLifecycleMoment> moments = <EventLifecycleMoment>[
      EventLifecycleMoment(
        title: 'Ideathon created',
        subtitle: 'Event record saved. Judge assignment is the next operational step and is not automatic.',
        at: event.createdAt,
        icon: AppIcons.ideathons,
        color: const Color(0xFF4F46E5),
      ),
      EventLifecycleMoment(
        title: hasAssignments ? 'Judge assignment started' : 'Judge assignment pending',
        subtitle: hasAssignments
            ? '${vm.workspace.assignmentCount} explicit idea → judge assignment${vm.workspace.assignmentCount == 1 ? '' : 's'}'
            : 'Optional at first — assign paid ideas to judges from Judge Assignments',
        at: vm.workspace.firstAssignedAt,
        icon: AppIcons.judges,
        color: const Color(0xFF7C3AED),
      ),
      EventLifecycleMoment(
        title: 'Scheduled window',
        subtitle: '${formatDateTime(event.startDateTime.toLocal())} – ${formatDateTime(event.endDateTime.toLocal())}',
        at: event.startDateTime,
        icon: AppIcons.event,
        color: const Color(0xFF0284C7),
      ),
      EventLifecycleMoment(
        title: evaluationStarted ? 'Evaluation began' : 'Evaluation not started',
        subtitle: evaluationStarted
            ? 'Judge assignments and integrity-sensitive configuration are locked'
            : 'Locking uses the first submitted evaluation, not the scheduled date alone',
        at: vm.workspace.evaluationStartedAt,
        icon: AppIcons.scoring,
        color: const Color(0xFFEA580C),
      ),
      EventLifecycleMoment(
        title: IdeathonStatusHelpers.label(event.status),
        subtitle: 'Current stored lifecycle status',
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
      stages: stages,
      currentId: currentId,
      moments: moments,
      embedded: embedded,
    );
  }
}
