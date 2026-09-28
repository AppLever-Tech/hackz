import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_metrics.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/menus/hackz_popup_menu.dart';

/// One event in a compact ideathon list (table cell or card).
class IdeathonListEntry {
  const IdeathonListEntry({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

/// One ideathon name, or icon + count with a dropdown that opens the workspace.
class IdeathonListCell extends StatelessWidget {
  const IdeathonListCell({
    super.key,
    required this.events,
    required this.onOpen,
    this.countNoun = 'Events',
  });

  final List<IdeathonListEntry> events;
  final void Function(IdeathonListEntry event) onOpen;
  final String countNoun;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
      );
    }

    if (events.length == 1) {
      final IdeathonListEntry event = events.first;
      final String label = event.name.trim().isEmpty ? event.id : event.name.trim();
      return ContextPill(
        label: label,
        semantic: ContextPillSemantic.event,
        icon: AppIcons.ideathons,
        onTap: () => onOpen(event),
        compact: true,
        fitContent: true,
        allowHoverScale: false,
      );
    }

    return _IdeathonCountMenu(
      events: events,
      countNoun: countNoun,
      onOpen: onOpen,
    );
  }
}

class _IdeathonCountMenu extends StatelessWidget {
  const _IdeathonCountMenu({
    required this.events,
    required this.countNoun,
    required this.onOpen,
  });

  final List<IdeathonListEntry> events;
  final String countNoun;
  final void Function(IdeathonListEntry event) onOpen;

  @override
  Widget build(BuildContext context) {
    final String label = '${events.length} $countNoun';
    final palette = ContextPillTheme.paletteFor(ContextPillSemantic.event);

    return PopupMenuButton<String>(
      tooltip: events.map((IdeathonListEntry e) => e.name).join(', '),
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
        for (final IdeathonListEntry event in events) {
          if (event.id == eventId) {
            onOpen(event);
            return;
          }
        }
      },
      itemBuilder: (BuildContext context) {
        return events
            .map(
              (IdeathonListEntry event) => PopupMenuItem<String>(
                value: event.id,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: HackzPopupMenuItemTile(
                  icon: AppIcons.ideathons,
                  label: event.name.trim().isEmpty ? event.id : event.name.trim(),
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
