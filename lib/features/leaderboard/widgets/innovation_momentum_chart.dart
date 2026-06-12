import 'package:flutter/material.dart';

/// Analytics line chart for time-series counts (e.g. evaluations per week).
class InnovationMomentumChart extends StatelessWidget {
  const InnovationMomentumChart({
    super.key,
    required this.series,
    this.lineColor = const Color(0xFF8B5CF6),
    this.height = 120,
  });

  final Map<String, int> series;
  final Color lineColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No momentum data yet', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      );
    }
    final entries = series.entries.toList(growable: false);
    final values = entries.map((e) => e.value.toDouble()).toList(growable: false);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _MomentumPainter(values: values, color: lineColor),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: <Widget>[
                Text(
                  entries.first.key,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                Text(
                  entries.last.key,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MomentumPainter extends CustomPainter {
  _MomentumPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    final pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2 - 14;

    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = pad + h * (i / 3);
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), grid);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length <= 1 ? pad + w / 2 : pad + (i / (values.length - 1)) * w;
      final y = pad + h - (values[i] / maxV) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final x = values.length <= 1 ? pad + w / 2 : pad + (i / (values.length - 1)) * w;
      final y = pad + h - (values[i] / maxV) * h;
      canvas.drawCircle(Offset(x, y), 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _MomentumPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
