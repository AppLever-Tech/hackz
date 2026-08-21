import 'package:flutter/material.dart';

import '../../../core/ui/common/mobile_compact_pill.dart';
import '../models/evaluator_source.dart';

/// Lightweight All / Judges filter row for the evaluator panel.
class EvaluatorFilterChips extends StatelessWidget {
  const EvaluatorFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final EvaluatorListFilter selected;
  final ValueChanged<EvaluatorListFilter> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final List<({String label, EvaluatorListFilter value})> options =
        <({String label, EvaluatorListFilter value})>[
      (label: 'All', value: EvaluatorListFilter.all),
      (label: 'Judges', value: EvaluatorListFilter.judges),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < options.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 6),
            compact
                ? MobileCompactPill(
                    label: options[i].label,
                    selected: selected == options[i].value,
                    onTap: () => onChanged(options[i].value),
                  )
                : _Chip(
                    label: options[i].label,
                    selected: selected == options[i].value,
                    onTap: () => onChanged(options[i].value),
                  ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? const Color(0xFF2E43C6) : const Color(0xFF475569);
    final Color bg = selected ? const Color(0xFFE8ECFF) : const Color(0xFFF1F5F9);
    final Color border = selected ? const Color(0xFF6A38FF) : const Color(0xFFE2E8F0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: selected ? 1.3 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
