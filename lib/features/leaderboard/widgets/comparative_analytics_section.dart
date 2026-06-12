import 'package:flutter/material.dart';

/// Side-by-side comparison bars + optional participation heat strip.
class ComparativeAnalyticsSection extends StatelessWidget {
  const ComparativeAnalyticsSection({
    super.key,
    required this.title,
    required this.labels,
    required this.values,
    this.maxBars = 6,
    this.barColor = const Color(0xFF6366F1),
  });

  final String title;
  final List<String> labels;
  final List<double> values;
  final int maxBars;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty || values.isEmpty) {
      return const SizedBox.shrink();
    }
    final n = labels.length.clamp(0, maxBars);
    final labs = labels.take(n).toList(growable: false);
    final vals = values.take(n).toList(growable: false);
    final maxV = vals.reduce((a, b) => a > b ? a : b).clamp(1e-6, double.infinity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 14),
          ...List<Widget>.generate(labs.length, (int i) {
            final v = vals[i];
            final ratio = (v / maxV).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          labs[i],
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        v.toStringAsFixed(v >= 10 ? 0 : 1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: Color.lerp(barColor, const Color(0xFF22D3EE), i / n) ?? barColor,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          _HeatStrip(values: vals, maxV: maxV),
        ],
      ),
    );
  }
}

class _HeatStrip extends StatelessWidget {
  const _HeatStrip({required this.values, required this.maxV});

  final List<double> values;
  final double maxV;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((v) {
        final intensity = (v / maxV).clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AspectRatio(
              aspectRatio: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color.lerp(const Color(0xFFEEF2FF), const Color(0xFF4F46E5), intensity) ??
                      const Color(0xFFEEF2FF),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
