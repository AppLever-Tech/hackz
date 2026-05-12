import 'package:flutter/material.dart';

/// Oval filter pill: icon + `label (count)` — matches SysAdmin organization filter styling.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.foregroundColor,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final Color fg = foregroundColor ?? (selected ? const Color(0xFF2E43C6) : const Color(0xFF475569));
    final Color bg = selected ? const Color(0xFFE8ECFF) : const Color(0xFFF1F5F9);
    final Color border = selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                count == 0 ? label : '$label ($count)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
