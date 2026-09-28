import 'package:flutter/material.dart';

/// Compact icon-only filter control used by import review and user tables.
class IconOnlyFilterButton extends StatelessWidget {
  const IconOnlyFilterButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.color,
    required this.onTap,
    this.size = 32,
    this.iconSize = 16,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.12) : const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? color.withValues(alpha: 0.55) : const Color(0xFFE2E8F0),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Icon(icon, size: iconSize, color: selected ? color : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }
}
