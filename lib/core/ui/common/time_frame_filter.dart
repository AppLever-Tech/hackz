import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Reusable compact timeframe selector for analytics charts.
class TimeFrameFilter<T> extends StatefulWidget {
  const TimeFrameFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    this.startPadding = TimeFrameFilter.defaultStartPadding,
    this.endPadding = TimeFrameFilter.defaultEndPadding,
  });

  static const double barHeight = 20;
  static const double defaultStartPadding = 2;
  static const double defaultEndPadding = 8;

  final List<T> options;
  final T selected;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;

  /// Prevents the first chip from clipping against the scroll viewport edge.
  final double startPadding;

  /// Space after the last chip when scrolled to the end.
  final double endPadding;

  @override
  State<TimeFrameFilter<T>> createState() => _TimeFrameFilterState<T>();
}

class _TimeFrameFilterState<T> extends State<TimeFrameFilter<T>> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TimeFrameFilter.barHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double viewportWidth = constraints.maxWidth;
          final bool expandToViewport =
              viewportWidth.isFinite && viewportWidth > 0;

          return ScrollConfiguration(
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: expandToViewport ? viewportWidth : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: _buildChips(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildChips() {
    final List<Widget> chips = <Widget>[];
    if (widget.startPadding > 0) {
      chips.add(SizedBox(width: widget.startPadding));
    }
    for (int i = 0; i < widget.options.length; i++) {
      if (i > 0) {
        chips.add(const SizedBox(width: 6));
      }
      final T option = widget.options[i];
      final bool isSelected = option == widget.selected;
      chips.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              widget.labelBuilder(option),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }
    if (widget.endPadding > 0) {
      chips.add(SizedBox(width: widget.endPadding));
    }
    return chips;
  }
}
