import 'package:flutter/material.dart';

/// Icon + label + value row for organization cards.
class OrgMetadataRow extends StatelessWidget {
  const OrgMetadataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.maxValueLines = 2,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxValueLines;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '—' : value.trim();
    final isEmpty = value.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    height: 1.1,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: <Widget>[
                          Text(
                            displayValue,
                            maxLines: maxValueLines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          if (trailing != null) trailing!,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
