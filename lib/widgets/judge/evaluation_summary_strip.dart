import 'package:flutter/material.dart';

/// Compact horizontal summary metrics for the judge evaluation workspace.
class EvaluationSummaryStrip extends StatelessWidget {
  const EvaluationSummaryStrip({
    super.key,
    required this.pendingCount,
    required this.evaluatedCount,
    required this.averageScore,
    required this.completionPercent,
  });

  final int pendingCount;
  final int evaluatedCount;
  final double? averageScore;
  final double completionPercent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        final chips = <_SummaryChipData>[
          _SummaryChipData(
            label: 'Pending',
            value: '$pendingCount',
            sub: 'Awaiting you',
            color: const Color(0xFFEA580C),
            icon: Icons.pending_actions_rounded,
          ),
          _SummaryChipData(
            label: 'Evaluated',
            value: '$evaluatedCount',
            sub: 'Your submissions',
            color: const Color(0xFF16A34A),
            icon: Icons.task_alt_rounded,
          ),
          _SummaryChipData(
            label: 'Avg score',
            value: averageScore == null ? '—' : averageScore!.toStringAsFixed(1),
            sub: 'Given by you',
            color: const Color(0xFF6366F1),
            icon: Icons.insights_rounded,
          ),
          _SummaryChipData(
            label: 'Completion',
            value: '${completionPercent.round()}%',
            sub: 'Of in-scope queue',
            color: const Color(0xFF0EA5E9),
            icon: Icons.pie_chart_outline_rounded,
          ),
        ];
        if (narrow) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((e) => SizedBox(width: (c.maxWidth - 8) / 2, child: _SummaryChip(data: e))).toList(),
          );
        }
        return Row(
          children: <Widget>[
            for (var i = 0; i < chips.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _SummaryChip(data: chips[i])),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryChipData {
  const _SummaryChipData({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.data});

  final _SummaryChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            data.color.withValues(alpha: 0.08),
            data.color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.label.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: data.color),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.1),
                ),
                Text(
                  data.sub,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
