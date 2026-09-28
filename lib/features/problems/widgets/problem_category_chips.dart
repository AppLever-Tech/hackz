import 'package:flutter/material.dart';

import '../constants/problem_constants.dart';

/// Read-only Software/Hardware chip row for problem detail surfaces.
class ProblemCategoryChips extends StatelessWidget {
  const ProblemCategoryChips({
    super.key,
    required this.selected,
    this.compact = false,
  });

  final String selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String? resolved = ProblemConstants.resolveCategory(selected);

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: ProblemConstants.categories.map((String category) {
        final bool isSelected = resolved == category;
        final Color fg = isSelected ? const Color(0xFF6A38FF) : const Color(0xFF64748B);
        final Color bg = isSelected ? const Color(0xFFF3EEFF) : const Color(0xFFF8FAFC);
        final Color border = isSelected ? const Color(0xFFD8CCFF) : const Color(0xFFE2E8F0);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 5 : 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: isSelected ? 1.4 : 1),
          ),
          child: Text(
            category,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
