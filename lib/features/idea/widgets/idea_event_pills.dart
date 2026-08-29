import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_metrics.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/menus/hackz_popup_menu.dart';
import '../../../utils/common_helpers.dart';
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
    if (events.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
      );
    }

    if (events.length == 1) {
      final IdeaEventParticipationSummary event = events.first;
      return ContextPill(
        label: event.eventName,
        semantic: ContextPillSemantic.event,
        icon: AppIcons.ideathons,
        onTap: () => onOpenEvent(event),
        compact: true,
        fitContent: true,
        allowHoverScale: false,
      );
    }

    return _EventsCountMenu(events: events, onOpenEvent: onOpenEvent);
  }
}

class _EventsCountMenu extends StatelessWidget {
  const _EventsCountMenu({
    required this.events,
    required this.onOpenEvent,
  });

  final List<IdeaEventParticipationSummary> events;
  final void Function(IdeaEventParticipationSummary event) onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final String label = '${events.length} Events';
    final palette = ContextPillTheme.paletteFor(ContextPillSemantic.event);

    return PopupMenuButton<String>(
      tooltip: events.map((IdeaEventParticipationSummary e) => e.eventName).join(', '),
      color: HackzPopupMenuStyle.panelColor,
      elevation: 14,
      shadowColor: HackzPopupMenuStyle.panelShadowColor,
      surfaceTintColor: Colors.transparent,
      position: PopupMenuPosition.under,
      offset: HackzPopupMenuStyle.defaultOffset,
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HackzPopupMenuStyle.panelRadius),
        side: const BorderSide(color: HackzPopupMenuStyle.panelBorderColor),
      ),
      padding: EdgeInsets.zero,
      onSelected: (String eventId) {
        for (final IdeaEventParticipationSummary event in events) {
          if (event.eventId == eventId) {
            onOpenEvent(event);
            return;
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return events
            .map(
              (IdeaEventParticipationSummary event) => PopupMenuItem<String>(
                value: event.eventId,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: HackzPopupMenuItemTile(
                  icon: AppIcons.ideathons,
                  label: event.eventName,
                ),
              ),
            )
            .toList(growable: false);
      },
      child: SizedBox(
        height: ContextPillMetrics.workspaceHeight,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  AppIcons.ideathons,
                  size: ContextPillMetrics.mobileCardPillIconSize,
                  color: palette.text,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.expand_more_rounded,
                  size: 14,
                  color: palette.text,
                ),
              ],
            ),
          ),
        ),
      ),
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
