import 'package:flutter/material.dart';

import '../models/problem_status.dart';
import '../services/problem_status_helpers.dart';

/// Horizontal lifecycle path highlighting [currentStatus].
class ProblemLifecycleStrip extends StatelessWidget {
  const ProblemLifecycleStrip({
    super.key,
    required this.currentStatus,
  });

  final ProblemStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final int currentIndex = ProblemStatus.lifecycleOrder.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Lifecycle',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            for (int i = 0; i < ProblemStatus.lifecycleOrder.length; i++) ...<Widget>[
              _LifecycleStepChip(
                status: ProblemStatus.lifecycleOrder[i],
                highlighted: i == currentIndex,
                completed: i < currentIndex,
              ),
              if (i < ProblemStatus.lifecycleOrder.length - 1)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: i < currentIndex ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _LifecycleStepChip extends StatelessWidget {
  const _LifecycleStepChip({
    required this.status,
    required this.highlighted,
    required this.completed,
  });

  final ProblemStatus status;
  final bool highlighted;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final Color color = ProblemStatusHelpers.color(status);
    final Color bg = highlighted
        ? ProblemStatusHelpers.background(status)
        : completed
            ? color.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC);
    final Color border = highlighted
        ? color.withValues(alpha: 0.45)
        : completed
            ? color.withValues(alpha: 0.25)
            : const Color(0xFFE2E8F0);
    final Color text = highlighted || completed ? color : const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: highlighted ? 1.4 : 1),
        boxShadow: highlighted
            ? <BoxShadow>[
                BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2)),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            completed && !highlighted ? Icons.check_rounded : ProblemStatusHelpers.icon(status),
            size: 14,
            color: text,
          ),
          const SizedBox(width: 5),
          Text(
            ProblemStatusHelpers.label(status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text),
          ),
        ],
      ),
    );
  }
}
