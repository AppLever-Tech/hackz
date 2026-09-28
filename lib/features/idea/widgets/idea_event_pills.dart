import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../utils/common_helpers.dart';
import '../../ideathons/widgets/ideathon_list_cell.dart';
import '../../ideathons/widgets/ideathon_status_pill.dart';
import '../../ideathons/widgets/ideathon_type_pill.dart';
import '../models/idea_event_participation_summary.dart';

/// Event identity in the ideas table: one name, or a rich dropdown for many.
class IdeaEventPills extends StatelessWidget {
  const IdeaEventPills({
    super.key,
    required this.events,
    required this.onOpenEvent,
  });

  final List<IdeaEventParticipationSummary> events;
  final void Function(IdeaEventParticipationSummary event) onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return IdeathonListCell(
      events: events
          .map(
            (IdeaEventParticipationSummary event) => IdeathonListEntry(
              id: event.eventId,
              name: event.eventName,
            ),
          )
          .toList(growable: false),
      onOpen: (IdeathonListEntry entry) {
        for (final IdeaEventParticipationSummary event in events) {
          if (event.eventId == entry.id) {
            onOpenEvent(event);
            return;
          }
        }
      },
    );
  }
}

/// One event participation row: event pill, type, status, and dates.
class IdeaEventParticipationRow extends StatelessWidget {
  const IdeaEventParticipationRow({
    super.key,
    required this.event,
    required this.onOpenEvent,
  });

  final IdeaEventParticipationSummary event;
  final VoidCallback onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final DateTime? start = event.startDateTime;
    final DateTime? end = event.endDateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            ContextPill(
              label: event.eventName,
              semantic: ContextPillSemantic.event,
              icon: AppIcons.ideathons,
              onTap: onOpenEvent,
              compact: true,
              fitContent: true,
            ),
            const SizedBox(width: 6),
            IdeathonTypePill(type: event.eventType),
            const SizedBox(width: 6),
            IdeathonStatusPill(status: event.eventStatus),
            if (start != null) ...<Widget>[
              const SizedBox(width: 8),
              Icon(AppIcons.event, size: 13, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                formatShortDate(start.toLocal()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
            if (end != null) ...<Widget>[
              const SizedBox(width: 4),
              const Text(
                '–',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(width: 4),
              Text(
                formatShortDate(end.toLocal()),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
