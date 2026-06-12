import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

/// Shared panel styling for Hackz popup menus and select fields.
abstract final class HackzPopupMenuStyle {
  static const Color panelColor = Colors.white;
  static const Color panelBorderColor = Color(0xFFE2E8F0);
  static const Color panelShadowColor = Color(0x220F172A);
  static const double panelRadius = 18;
  static const double defaultMinWidth = 190;
  static const Offset defaultOffset = Offset(0, 8);
}

/// One action in a [HackzPopupMenuButton] panel.
class HackzMenuAction {
  const HackzMenuAction({
    required this.value,
    required this.icon,
    required this.label,
    this.enabled = true,
    this.danger = false,
  });

  final String value;
  final IconData icon;
  final String label;
  final bool enabled;
  final bool danger;
}

/// Premium Hackz-themed popup menu — shared panel styling for headers, tables, cards, etc.
class HackzPopupMenuButton extends StatelessWidget {
  const HackzPopupMenuButton({
    super.key,
    required this.tooltip,
    required this.actions,
    required this.onSelected,
    required this.child,
    this.dividersBefore = const <String>{},
    this.minWidth = HackzPopupMenuStyle.defaultMinWidth,
    this.offset = HackzPopupMenuStyle.defaultOffset,
    this.position = PopupMenuPosition.under,
  });

  final String tooltip;
  final List<HackzMenuAction> actions;
  final ValueChanged<String> onSelected;
  final Widget child;
  final Set<String> dividersBefore;
  final double minWidth;
  final Offset offset;
  final PopupMenuPosition position;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      color: HackzPopupMenuStyle.panelColor,
      elevation: 14,
      shadowColor: HackzPopupMenuStyle.panelShadowColor,
      surfaceTintColor: Colors.transparent,
      position: position,
      offset: offset,
      constraints: BoxConstraints(minWidth: minWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HackzPopupMenuStyle.panelRadius),
        side: const BorderSide(color: HackzPopupMenuStyle.panelBorderColor),
      ),
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => _buildEntries(),
      child: child,
    );
  }

  List<PopupMenuEntry<String>> _buildEntries() {
    final entries = <PopupMenuEntry<String>>[];
    for (final HackzMenuAction action in actions) {
      if (dividersBefore.contains(action.value)) {
        entries.add(const PopupMenuDivider(height: 8));
      }
      entries.add(
        PopupMenuItem<String>(
          value: action.value,
          enabled: action.enabled,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: HackzPopupMenuItemTile(
            icon: action.icon,
            label: action.label,
            enabled: action.enabled,
            danger: action.danger,
          ),
        ),
      );
    }
    return entries;
  }
}

/// Bordered ⋮ trigger used in data tables and dashboard chrome.
class HackzPopupMenuOverflowTrigger extends StatelessWidget {
  const HackzPopupMenuOverflowTrigger({
    super.key,
    this.size = 34,
    this.iconSize = 20,
  });

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HackzPopupMenuStyle.panelBorderColor),
      ),
      child: Icon(AppIcons.more, size: iconSize, color: const Color(0xFF475569)),
    );
  }
}

/// Rich row inside a Hackz popup panel.
class HackzPopupMenuItemTile extends StatelessWidget {
  const HackzPopupMenuItemTile({
    super.key,
    required this.icon,
    required this.label,
    this.enabled = true,
    this.danger = false,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool danger;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color accent = !enabled
        ? const Color(0xFF94A3B8)
        : danger
            ? const Color(0xFFDC2626)
            : const Color(0xFF4F46E5);
    final Color color = selected && enabled ? const Color(0xFF6A38FF) : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: enabled
            ? color.withValues(alpha: selected ? 0.12 : 0.07)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: selected && enabled ? Border.all(color: color.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: enabled ? color.withValues(alpha: 0.11) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: danger && enabled ? color : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (selected && enabled) ...<Widget>[
            const SizedBox(width: 6),
            Icon(Icons.check_rounded, size: 16, color: color),
          ],
        ],
      ),
    );
  }
}
