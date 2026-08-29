import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/menus/hackz_popup_menu.dart';
import '../models/event_details_module.dart';

/// Compact Event Details navigation: peer tabs + grouped dropdowns.
///
/// Desktop/tablet-wide: five compact items with Evaluation/Outcome menus.
/// Narrow viewports: a single section selector (no wide tab strip).
class EventDetailsNavBar extends StatelessWidget {
  const EventDetailsNavBar({
    super.key,
    required this.groups,
    required this.selectedId,
    required this.onSelected,
  });

  final List<EventDetailsNavGroup> groups;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < ResponsiveBreakpoints.tablet;
        if (compact) {
          return _MobileSelector(
            groups: groups,
            selectedId: selectedId,
            onSelected: onSelected,
          );
        }
        return _DesktopBar(
          groups: groups,
          selectedId: selectedId,
          onSelected: onSelected,
        );
      },
    );
  }
}

class _DesktopBar extends StatelessWidget {
  const _DesktopBar({
    required this.groups,
    required this.selectedId,
    required this.onSelected,
  });

  final List<EventDetailsNavGroup> groups;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < groups.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: groups[i].isGroup
                  ? _GroupChip(
                      group: groups[i],
                      selectedId: selectedId,
                      onSelected: onSelected,
                    )
                  : _LeafChip(
                      module: groups[i].items.first,
                      selected: groups[i].items.first.id == selectedId,
                      onTap: () => onSelected(groups[i].items.first.id),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeafChip extends StatelessWidget {
  const _LeafChip({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final EventDetailsModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _NavChipSurface(
      selected: selected,
      onTap: onTap,
      child: _navChipLabel(
        icon: module.icon,
        label: _labelWithCount(module.label, module.count),
        selected: selected,
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.group,
    required this.selectedId,
    required this.onSelected,
  });

  final EventDetailsNavGroup group;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final bool selected = group.items.any((EventDetailsModule m) => m.id == selectedId);
    return PopupMenuButton<String>(
      tooltip: group.label,
      color: HackzPopupMenuStyle.panelColor,
      elevation: 14,
      shadowColor: HackzPopupMenuStyle.panelShadowColor,
      surfaceTintColor: Colors.transparent,
      position: PopupMenuPosition.under,
      offset: HackzPopupMenuStyle.defaultOffset,
      constraints: const BoxConstraints(minWidth: 220),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HackzPopupMenuStyle.panelRadius),
        side: const BorderSide(color: HackzPopupMenuStyle.panelBorderColor),
      ),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        return group.items
            .map(
              (EventDetailsModule m) => PopupMenuItem<String>(
                value: m.id,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: HackzPopupMenuItemTile(
                  icon: m.icon ?? group.icon ?? AppIcons.info,
                  label: _labelWithCount(m.label, m.count),
                  selected: m.id == selectedId,
                ),
              ),
            )
            .toList(growable: false);
      },
      child: _NavChipSurface(
        selected: selected,
        child: _navChipLabel(
          icon: group.icon,
          label: group.label,
          selected: selected,
          trailing: Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _MobileSelector extends StatelessWidget {
  const _MobileSelector({
    required this.groups,
    required this.selectedId,
    required this.onSelected,
  });

  final List<EventDetailsNavGroup> groups;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    EventDetailsModule? current;
    String groupLabel = '';
    for (final EventDetailsNavGroup g in groups) {
      for (final EventDetailsModule m in g.items) {
        if (m.id == selectedId) {
          current = m;
          groupLabel = g.isGroup ? g.label : '';
        }
      }
    }
    final String title = current == null
        ? groups.first.label
        : groupLabel.isEmpty
            ? _labelWithCount(current.label, current.count)
            : '$groupLabel · ${current.label}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: PopupMenuButton<String>(
        tooltip: 'Event section',
        color: HackzPopupMenuStyle.panelColor,
        elevation: 14,
        shadowColor: HackzPopupMenuStyle.panelShadowColor,
        surfaceTintColor: Colors.transparent,
        position: PopupMenuPosition.under,
        offset: HackzPopupMenuStyle.defaultOffset,
        constraints: const BoxConstraints(minWidth: 240),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HackzPopupMenuStyle.panelRadius),
          side: const BorderSide(color: HackzPopupMenuStyle.panelBorderColor),
        ),
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        itemBuilder: (BuildContext context) {
          final List<PopupMenuEntry<String>> entries = <PopupMenuEntry<String>>[];
          for (int i = 0; i < groups.length; i++) {
            final EventDetailsNavGroup g = groups[i];
            if (g.isGroup) {
              if (entries.isNotEmpty) {
                entries.add(const PopupMenuDivider(height: 8));
              }
              entries.add(
                PopupMenuItem<String>(
                  value: '__group_${g.id}',
                  enabled: false,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    g.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
              for (final EventDetailsModule m in g.items) {
                entries.add(_leafItem(m));
              }
            } else {
              entries.add(_leafItem(g.items.first));
            }
          }
          return entries;
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              if (current?.icon != null) ...<Widget>[
                Icon(current!.icon, size: 18, color: const Color(0xFF0F172A)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Icon(Icons.expand_more_rounded, size: 20, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _leafItem(EventDetailsModule m) {
    return PopupMenuItem<String>(
      value: m.id,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: HackzPopupMenuItemTile(
        icon: m.icon ?? AppIcons.info,
        label: _labelWithCount(m.label, m.count),
        selected: m.id == selectedId,
      ),
    );
  }
}

class _NavChipSurface extends StatelessWidget {
  const _NavChipSurface({
    required this.selected,
    required this.child,
    this.onTap,
  });

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget body = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: body,
      ),
    );
  }
}

TextStyle _navLabelStyle(bool selected) {
  return TextStyle(
    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
    fontSize: 13,
    color: selected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
  );
}

String _labelWithCount(String label, int? count) {
  if (count == null) return label;
  return '$label ($count)';
}

Widget _navChipLabel({
  required IconData? icon,
  required String label,
  required bool selected,
  Widget? trailing,
}) {
  final Color color = selected ? const Color(0xFF0F172A) : const Color(0xFF64748B);
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      if (icon != null) ...<Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
      ],
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: _navLabelStyle(selected),
        ),
      ),
      if (trailing != null) ...<Widget>[
        const SizedBox(width: 2),
        trailing,
      ],
    ],
  );
}
