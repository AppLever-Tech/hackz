import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import 'evaluation_workspace_loader.dart';

class EvaluationScoresSection extends StatelessWidget {
  const EvaluationScoresSection({super.key, required this.vm});

  final EvaluationWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(AppIcons.insights, size: 18, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text(
              'Criteria scores',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (vm.criteria.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No per-criterion data recorded for this evaluation.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          )
        else
          ...vm.criteria.map(_criterionBar),
      ],
    );
  }

  Widget _criterionBar(EvaluationCriterionScore c) {
    final double pct = c.maxValue <= 0 ? 0 : (c.value / c.maxValue).clamp(0.0, 1.0);
    final Color accent = switch (pct) {
      >= 0.8 => const Color(0xFF047857),
      >= 0.6 => const Color(0xFF6366F1),
      _ => const Color(0xFFEA580C),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  c.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                ),
              ),
              Text(
                '${c.value.toStringAsFixed(1)} / ${c.maxValue}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
