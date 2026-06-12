import 'package:flutter/material.dart';

import '../../../shared/menus/hackz_popup_menu.dart';

export '../../../shared/menus/hackz_popup_menu.dart';

typedef CardOverflowMenuAction = HackzMenuAction;

typedef RichPopupMenuItemTile = HackzPopupMenuItemTile;

/// Bordered ⋮ trigger with themed rich popup items (faculty teams, judge cards, etc.).
class CardOverflowMenuButton extends StatelessWidget {
  const CardOverflowMenuButton({
    super.key,
    required this.tooltip,
    required this.actions,
    required this.onSelected,
    this.dividersBefore = const <String>{},
    this.minWidth = HackzPopupMenuStyle.defaultMinWidth,
  });

  final String tooltip;
  final List<CardOverflowMenuAction> actions;
  final ValueChanged<String> onSelected;
  final Set<String> dividersBefore;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return HackzPopupMenuButton(
      tooltip: tooltip,
      actions: actions,
      onSelected: onSelected,
      dividersBefore: dividersBefore,
      minWidth: minWidth,
      child: const HackzPopupMenuOverflowTrigger(),
    );
  }
}
