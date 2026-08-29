import 'package:flutter/material.dart';

import '../ui/menus/hackz_popup_menu.dart';

/// Compact section switcher for mobile workspace navigation.
///
/// Replaces horizontally scrollable [TabBar]s on small screens with a
/// premium dropdown that lists every section without overflow.
class WorkspaceSectionSwitcher extends StatelessWidget {
  const WorkspaceSectionSwitcher({
    super.key,
    required this.titles,
    required this.selectedIndex,
    required this.onChanged,
    this.icons,
  }) : assert(titles.length > 0);

  final List<String> titles;
  final List<IconData?>? icons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const Color _barBackground = Color(0xFFF1F5F9);
  static const Color _triggerBackground = Colors.white;
  static const Color _labelColor = Color(0xFF0F172A);
  static const Color _chevronColor = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final int safeIndex = selectedIndex.clamp(0, titles.length - 1);
    final String currentTitle = titles[safeIndex];

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: _barBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double triggerWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : double.infinity;
            final double panelWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : HackzPopupMenuStyle.defaultMinWidth;

            return PopupMenuButton<int>(
              color: HackzPopupMenuStyle.panelColor,
              elevation: 14,
              shadowColor: HackzPopupMenuStyle.panelShadowColor,
              surfaceTintColor: Colors.transparent,
              position: PopupMenuPosition.under,
              offset: HackzPopupMenuStyle.defaultOffset,
              constraints: BoxConstraints(minWidth: panelWidth),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HackzPopupMenuStyle.panelRadius),
                side: const BorderSide(color: HackzPopupMenuStyle.panelBorderColor),
              ),
              padding: EdgeInsets.zero,
              onSelected: onChanged,
              itemBuilder: (BuildContext context) {
                return List<PopupMenuEntry<int>>.generate(titles.length, (int index) {
                  return PopupMenuItem<int>(
                    value: index,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: HackzPopupMenuItemTile(
                      icon: _iconAt(index) ?? Icons.view_agenda_outlined,
                      label: titles[index],
                      selected: index == safeIndex,
                    ),
                  );
                }, growable: false);
              },
              child: SizedBox(
                width: triggerWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _triggerBackground,
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
                      if (_iconAt(safeIndex) != null) ...<Widget>[
                        Icon(_iconAt(safeIndex), size: 18, color: _labelColor),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          currentTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _labelColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.expand_more_rounded, size: 20, color: _chevronColor),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData? _iconAt(int index) {
    final List<IconData?>? icons = this.icons;
    if (icons == null || index < 0 || index >= icons.length) return null;
    return icons[index];
  }
}
