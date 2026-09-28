import 'package:flutter/material.dart';

import '../models/event_lifecycle_stage.dart';

/// Horizontal lifecycle path shared by Ideathon and future Hackathon details.
class EventLifecycleStrip extends StatelessWidget {
  const EventLifecycleStrip({
    super.key,
    required this.stages,
    required this.currentId,
  });

  final List<EventLifecycleStage> stages;
  final String currentId;

  @override
  Widget build(BuildContext context) {
    final int currentIndex = stages.indexWhere((EventLifecycleStage s) => s.id == currentId);

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
            for (int i = 0; i < stages.length; i++) ...<Widget>[
              _StageChip(
                stage: stages[i],
                highlighted: i == currentIndex,
                completed: currentIndex >= 0 && i < currentIndex,
              ),
              if (i < stages.length - 1)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: currentIndex >= 0 && i < currentIndex ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.stage,
    required this.highlighted,
    required this.completed,
  });

  final EventLifecycleStage stage;
  final bool highlighted;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final Color color = stage.color;
    final Color bg = highlighted
        ? color.withValues(alpha: 0.12)
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
            ? <BoxShadow>[BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            completed && !highlighted ? Icons.check_rounded : stage.icon,
            size: 14,
            color: text,
          ),
          const SizedBox(width: 5),
          Text(
            stage.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text),
          ),
        ],
      ),
    );
  }
}
