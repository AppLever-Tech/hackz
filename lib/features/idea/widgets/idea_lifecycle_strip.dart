import 'package:flutter/material.dart';

import '../models/enums/idea_status.dart';
import '../services/idea_status_helpers.dart';

/// Horizontal lifecycle path highlighting the current [IdeaStatus].
class IdeaLifecycleStrip extends StatelessWidget {
  const IdeaLifecycleStrip({
    super.key,
    required this.currentStatus,
  });

  final IdeaStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final int currentIndex = IdeaStatusHelpers.lifecycleIndex(currentStatus);

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
            for (int i = 0; i < IdeaStatus.lifecycleOrder.length; i++) ...<Widget>[
              _LifecycleStepChip(
                status: IdeaStatus.lifecycleOrder[i],
                highlighted: i == currentIndex,
                completed: currentIndex >= 0 && i < currentIndex,
                rejected: currentStatus == IdeaStatus.rejected &&
                    IdeaStatus.lifecycleOrder[i] == IdeaStatus.readyForShortlisting,
              ),
              if (i < IdeaStatus.lifecycleOrder.length - 1)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: currentIndex >= 0 && i < currentIndex
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFFCBD5E1),
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
    required this.rejected,
  });

  final IdeaStatus status;
  final bool highlighted;
  final bool completed;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final Color color = rejected && highlighted
        ? IdeaStatusHelpers.color(IdeaStatus.rejected)
        : IdeaStatusHelpers.color(status);
    final Color bg = highlighted
        ? IdeaStatusHelpers.background(rejected ? IdeaStatus.rejected : status)
        : completed
            ? color.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC);
    final Color border = highlighted
        ? color.withValues(alpha: 0.45)
        : completed
            ? color.withValues(alpha: 0.25)
            : const Color(0xFFE2E8F0);
    final Color text = highlighted || completed ? color : const Color(0xFF94A3B8);
    final String label = rejected && highlighted ? 'Rejected' : IdeaStatusHelpers.label(status);

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
            completed && !highlighted ? Icons.check_rounded : IdeaStatusHelpers.icon(status),
            size: 14,
            color: text,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text),
          ),
        ],
      ),
    );
  }
}
