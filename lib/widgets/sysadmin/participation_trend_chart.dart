import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/sysadmin_dashboard_service.dart';
import 'platform_timeframe_filter.dart';

class ParticipationTrendChart extends StatelessWidget {
  const ParticipationTrendChart({
    super.key,
    required this.points,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  final List<PlatformTrendPoint> points;
  final PlatformAnalyticsTimeframe selectedTimeframe;
  final ValueChanged<PlatformAnalyticsTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final Widget title = const Text(
              'Platform Participation Growth Trend',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            );
            final Widget filter = PlatformTimeframeFilter(
              selected: selectedTimeframe,
              onChanged: onTimeframeChanged,
            );
            if (c.maxWidth < 720) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  title,
                  const SizedBox(height: 10),
                  filter,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: title),
                const SizedBox(width: 12),
                filter,
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          '${selectedTimeframe.label} activity across users, teams, submissions and evaluations',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 250,
          child: points.isEmpty
              ? const Center(child: Text('No activity data yet'))
              : CustomPaint(
                  painter: _TrendPainter(points),
                  child: const SizedBox.expand(),
                ),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 12,
          runSpacing: 8,
          children: <Widget>[
            _Legend(color: Color(0xFF6A38FF), label: 'Users'),
            _Legend(color: Color(0xFF0EA5E9), label: 'Teams'),
            _Legend(color: Color(0xFFEA580C), label: 'Ideas'),
            _Legend(color: Color(0xFF16A34A), label: 'Evaluations'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points);

  final List<PlatformTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final double left = 34;
    final double right = 10;
    final double top = 10;
    final double bottom = 28;
    final Rect plot = Rect.fromLTWH(left, top, size.width - left - right, size.height - top - bottom);

    final Paint grid = Paint()
      ..color = const Color(0xFFE8ECF8)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    final int maxValue = math.max(
      1,
      points
          .expand((p) => <int>[p.users, p.teams, p.ideas, p.evaluations])
          .fold<int>(0, math.max),
    );

    void drawSeries(List<int> values, Color color) {
      final Paint stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final Paint dot = Paint()..color = color;
      final Path path = Path();
      for (int i = 0; i < values.length; i++) {
        final double x = values.length == 1 ? plot.center.dx : plot.left + (plot.width * i / (values.length - 1));
        final double y = plot.bottom - (values[i] / maxValue) * plot.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.2, dot);
      }
      canvas.drawPath(path, stroke);
    }

    drawSeries(points.map((p) => p.users).toList(growable: false), const Color(0xFF6A38FF));
    drawSeries(points.map((p) => p.teams).toList(growable: false), const Color(0xFF0EA5E9));
    drawSeries(points.map((p) => p.ideas).toList(growable: false), const Color(0xFFEA580C));
    drawSeries(points.map((p) => p.evaluations).toList(growable: false), const Color(0xFF16A34A));

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1 ? plot.center.dx : plot.left + (plot.width * i / (points.length - 1));
      tp.text = TextSpan(text: points[i].label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)));
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + 9));
    }
    for (int i = 0; i <= 4; i++) {
      final int value = (maxValue * (4 - i) / 4).round();
      final y = plot.top + plot.height * i / 4;
      tp.text = TextSpan(text: '$value', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)));
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.points != points;
}
