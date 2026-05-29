import 'package:flutter/material.dart';

class SettingsNumberStepper extends StatelessWidget {
  const SettingsNumberStepper({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.loading = false,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool canDec = value > min;
    final bool canInc = value < max;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: loading || !canDec ? null : () => onChanged((value - step).clamp(min, max)),
            icon: const Icon(Icons.remove_rounded, size: 20),
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '$value',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: loading || !canInc ? null : () => onChanged((value + step).clamp(min, max)),
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
