import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/coordinator_dashboard_service.dart';
import '../common/time_frame_filter.dart';
import 'coordinator_panel_card.dart';

class VerificationTrendChart extends StatelessWidget {
  const VerificationTrendChart({
    super.key,
    required this.points,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  final List<CoordinatorTrendPoint> points;
  final CoordinatorDashboardTimeframe selectedTimeframe;
  final ValueChanged<CoordinatorDashboardTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    return CoordinatorPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: <Widget>[
              const _TitleBlock(
                title: 'Payment Verification Trend',
                subtitle: 'Submitted, verified and rejected payments over time',
              ),
              TimeFrameFilter<CoordinatorDashboardTimeframe>(
                options: CoordinatorDashboardTimeframe.values,
                selected: selectedTimeframe,
                labelBuilder: (option) => option.label,
                onChanged: onTimeframeChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: points.isEmpty
                ? const Center(child: Text('No payment trend data yet.'))
                : CustomPaint(
                    painter: _VerificationTrendPainter(points),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 14,
            runSpacing: 8,
            children: <Widget>[
              _LegendDot(label: 'Submitted', color: Color(0xFF0EA5E9)),
              _LegendDot(label: 'Verified', color: Color(0xFF16A34A)),
              _LegendDot(label: 'Rejected', color: Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationTrendPainter extends CustomPainter {
  const _VerificationTrendPainter(this.points);

  final List<CoordinatorTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final labelStyle = const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700);
    final axisPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    const left = 34.0;
    const bottom = 28.0;
    const top = 8.0;
    final chartWidth = math.max(1.0, size.width - left - 6);
    final chartHeight = math.max(1.0, size.height - top - bottom);
    final maxValue = math.max(
      1,
      points.fold<int>(0, (max, p) => math.max(max, math.max(p.submitted, math.max(p.verified, p.rejected)))),
    );
    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(left + chartWidth, y), axisPaint);
    }
    void drawSeries(int Function(CoordinatorTrendPoint p) value, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final x = left + chartWidth * (points.length == 1 ? 0 : i / (points.length - 1));
        final y = top + chartHeight - (value(points[i]) / maxValue) * chartHeight;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.2, Paint()..color = color);
      }
      canvas.drawPath(path, paint);
    }

    drawSeries((p) => p.submitted, const Color(0xFF0EA5E9));
    drawSeries((p) => p.verified, const Color(0xFF16A34A));
    drawSeries((p) => p.rejected, const Color(0xFFDC2626));

    for (var i = 0; i < points.length; i++) {
      final x = left + chartWidth * (points.length == 1 ? 0 : i / (points.length - 1));
      final tp = TextPainter(text: TextSpan(text: points[i].label, style: labelStyle), textDirection: TextDirection.ltr)..layout(maxWidth: 54);
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _VerificationTrendPainter oldDelegate) => oldDelegate.points != points;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

