import 'package:flutter/gestures.dart';
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

  static const double barHeight = 28;

  final List<T> options;
  final T selected;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: barHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: <PointerDeviceKind>{
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.stylus,
            PointerDeviceKind.trackpad,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          primary: false,
          physics: const ClampingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: _buildChips(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChips() {
    final List<Widget> chips = <Widget>[];
    for (int i = 0; i < options.length; i++) {
      if (i > 0) {
        chips.add(const SizedBox(width: 6));
      }
      final T option = options[i];
      final bool isSelected = option == selected;
      chips.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              labelBuilder(option),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }
    return chips;
  }
}
