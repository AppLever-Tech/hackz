import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../models/idea_event_participation_summary.dart';

/// Compact event pills with a `+N` overflow when an idea joined multiple events.
class IdeaEventPills extends StatelessWidget {
  const IdeaEventPills({
    super.key,
    required this.events,
    required this.onOpenEvent,
    this.maxVisible = 2,
  });

  final List<IdeaEventParticipationSummary> events;
  final void Function(IdeaEventParticipationSummary event) onOpenEvent;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
      );
    }

    final int visibleCount = events.length <= maxVisible ? events.length : maxVisible;
    final List<IdeaEventParticipationSummary> visible = events.take(visibleCount).toList(growable: false);
    final List<IdeaEventParticipationSummary> overflow = events.skip(visibleCount).toList(growable: false);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final IdeaEventParticipationSummary event in visible)
          ContextPill(
            label: event.eventName,
            semantic: ContextPillSemantic.event,
            icon: AppIcons.ideathons,
            onTap: () => onOpenEvent(event),
            compact: true,
            fitContent: true,
            allowHoverScale: false,
          ),
        if (overflow.isNotEmpty) _OverflowChip(hidden: overflow, onOpenEvent: onOpenEvent),
      ],
    );
  }
}

class _OverflowChip extends StatelessWidget {
  const _OverflowChip({
    required this.hidden,
    required this.onOpenEvent,
  });

  final List<IdeaEventParticipationSummary> hidden;
  final void Function(IdeaEventParticipationSummary event) onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: hidden.map((e) => e.eventName).join(', '),
      onSelected: (String eventId) {
        for (final IdeaEventParticipationSummary event in hidden) {
          if (event.eventId == eventId) {
            onOpenEvent(event);
            return;
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return hidden
            .map(
              (IdeaEventParticipationSummary event) => PopupMenuItem<String>(
                value: event.eventId,
                child: Text(event.eventName, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(growable: false);
      },
      child: EntityCardPills.meta('+${hidden.length}', icon: AppIcons.ideathons),
    );
  }
}

/// One event participation row: event pill plus event-scoped status chips.
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ContextPill(
            label: event.eventName,
            semantic: ContextPillSemantic.event,
            icon: AppIcons.ideathons,
            onTap: onOpenEvent,
            compact: true,
            fitContent: true,
          ),
          EntityCardPills.meta(event.paymentLabel, icon: AppIcons.payments),
          EntityCardPills.meta(
            event.evaluationLabel,
            icon: event.evaluated ? AppIcons.statusEvaluated : AppIcons.clock,
          ),
          if (event.scoreLabel != null) EntityCardPills.meta(event.scoreLabel!, icon: AppIcons.scoring),
        ],
      ),
    );
  }
}
