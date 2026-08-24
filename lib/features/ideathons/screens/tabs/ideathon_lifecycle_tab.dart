import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/features/events/models/event_lifecycle_stage.dart';
import 'package:hackz/features/events/widgets/event_lifecycle_section.dart';
import 'package:hackz/features/ideathons/models/ideathon_status.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';
import 'package:hackz/features/ideathons/services/ideathon_status_helpers.dart';
import 'package:hackz/utils/common_helpers.dart';

class IdeathonLifecycleTab extends StatelessWidget {
  const IdeathonLifecycleTab({super.key, required this.vm});

  final IdeathonDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final event = vm.ideathon;
    final List<EventLifecycleStage> stages = IdeathonStatus.lifecycleOrder
        .map(
          (IdeathonStatus status) => EventLifecycleStage(
            id: status.value,
            label: IdeathonStatusHelpers.label(status),
            icon: IdeathonStatusHelpers.icon(status),
            color: IdeathonStatusHelpers.color(status),
          ),
        )
        .toList(growable: false);

    final List<EventLifecycleMoment> moments = <EventLifecycleMoment>[
      EventLifecycleMoment(
        title: 'Ideathon created',
        subtitle: 'Event record saved',
        at: event.createdAt,
        icon: AppIcons.ideathons,
        color: const Color(0xFF4F46E5),
      ),
      EventLifecycleMoment(
        title: 'Scheduled window',
        subtitle: '${formatDateTime(event.startDateTime.toLocal())} – ${formatDateTime(event.endDateTime.toLocal())}',
        at: event.startDateTime,
        icon: AppIcons.event,
        color: const Color(0xFF0284C7),
      ),
      EventLifecycleMoment(
        title: IdeathonStatusHelpers.label(event.status),
        subtitle: 'Current lifecycle state',
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
      currentId: event.status.value,
      moments: moments,
      title: 'Ideathon lifecycle',
    );
  }
}
