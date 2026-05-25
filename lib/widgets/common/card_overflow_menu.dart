import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';

/// One action in a [CardOverflowMenuButton] dropdown.
class CardOverflowMenuAction {
  const CardOverflowMenuAction({
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

/// Bordered ⋮ trigger with themed rich popup items (faculty teams, judge cards, etc.).
class CardOverflowMenuButton extends StatelessWidget {
  const CardOverflowMenuButton({
    super.key,
    required this.tooltip,
    required this.actions,
    required this.onSelected,
    this.dividersBefore = const <String>{},
    this.minWidth = 190,
  });

  final String tooltip;
  final List<CardOverflowMenuAction> actions;
  final ValueChanged<String> onSelected;
  final Set<String> dividersBefore;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: tooltip,
      color: Colors.white,
      elevation: 14,
      shadowColor: const Color(0x220F172A),
      surfaceTintColor: Colors.transparent,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      constraints: BoxConstraints(minWidth: minWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.zero,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(AppIcons.more, size: 20, color: Color(0xFF475569)),
      ),
      onSelected: onSelected,
      itemBuilder: (BuildContext context) {
        final entries = <PopupMenuEntry<String>>[];
        for (final action in actions) {
          if (dividersBefore.contains(action.value)) {
            entries.add(const PopupMenuDivider(height: 8));
          }
          entries.add(
            PopupMenuItem<String>(
              value: action.value,
              enabled: action.enabled,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: RichPopupMenuItemTile(
                icon: action.icon,
                label: action.label,
                enabled: action.enabled,
                danger: action.danger,
              ),
            ),
          );
        }
        return entries;
      },
    );
  }
}

/// Rich row inside a [CardOverflowMenuButton] panel.
class RichPopupMenuItemTile extends StatelessWidget {
  const RichPopupMenuItemTile({
    super.key,
    required this.icon,
    required this.label,
    this.enabled = true,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? const Color(0xFF94A3B8)
        : danger
            ? const Color(0xFFDC2626)
            : const Color(0xFF4F46E5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: enabled ? color.withValues(alpha: 0.07) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
  }
}
