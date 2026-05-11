import 'package:flutter/material.dart';

/// Reusable compact timeframe selector for analytics charts.
class TimeFrameFilter<T> extends StatelessWidget {
  const TimeFrameFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((T option) {
        final bool isSelected = option == selected;
        return ChoiceChip(
          label: Text(
            labelBuilder(option),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(option),
          selectedColor: const Color(0xFFEDE9FE),
          backgroundColor: const Color(0xFFF8FAFC),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          side: BorderSide(color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0)),
        );
      }).toList(growable: false),
    );
  }
}
