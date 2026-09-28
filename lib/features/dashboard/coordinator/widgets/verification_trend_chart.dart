import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../chrome/dashboard_components.dart';
import '../services/coordinator_dashboard_service.dart';
import '../../../../core/ui/common/dashboard_trend_chart_layout.dart';
import '../../../../core/ui/common/time_frame_filter.dart';

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

  static const List<({String label, Color color})> _series = <({String label, Color color})>[
    (label: 'Submitted', color: Color(0xFF0EA5E9)),
    (label: 'Verified', color: Color(0xFF16A34A)),
    (label: 'Rejected', color: Color(0xFFDC2626)),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = points.isEmpty ||
        points.every(
          (CoordinatorTrendPoint p) => p.submitted == 0 && p.verified == 0 && p.rejected == 0,
        );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool bounded = constraints.maxHeight.isFinite;
        final Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            DashboardCardHeaderRow(
              title: 'Payment Verification Trend',
              icon: AppIcons.verification,
              stackBelowWidth: 360,
              trailing: TimeFrameFilter<CoordinatorDashboardTimeframe>(
                options: CoordinatorDashboardTimeframe.values,
                selected: selectedTimeframe,
                labelBuilder: (CoordinatorDashboardTimeframe option) => option.label,
                onChanged: onTimeframeChanged,
                endPadding: 14,
              ),
            ),
            const SizedBox(height: DashboardTrendChartLayout.headerToSubtitleGap),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  'Submitted, verified and rejected payments over time',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                for (final ({String label, Color color}) entry in _series)
                  _TrendLegend(color: entry.color, label: entry.label),
              ],
            ),
            const SizedBox(height: DashboardTrendChartLayout.subtitleToChartGap),
            if (bounded)
              Expanded(child: _chartArea(isEmpty))
            else
              _chartArea(isEmpty),
          ],
        );
        return content;
      },
    );
  }

  Widget _chartArea(bool isEmpty) {
    return SizedBox(
      height: DashboardTrendChartLayout.chartBoxHeight,
      width: double.infinity,
      child: isEmpty
          ? const Center(child: Text('No payment trend data yet.'))
          : CustomPaint(
              painter: _VerificationTrendPainter(points),
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _TrendLegend extends StatelessWidget {
  const _TrendLegend({required this.color, required this.label});

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

class _VerificationTrendPainter extends CustomPainter {
  const _VerificationTrendPainter(this.points);

  final List<CoordinatorTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = DashboardTrendChartLayout.plotRect(size);
    final Paint grid = Paint()
      ..color = const Color(0xFFE8ECF8)
      ..strokeWidth = 1;
    for (int i = 0; i <= DashboardTrendChartLayout.yAxisTickCount; i++) {
      final double y = DashboardTrendChartLayout.yAxisLineY(plot, i);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    final int maxValue = math.max(
      1,
      points.fold<int>(
        0,
        (int max, CoordinatorTrendPoint p) =>
            math.max(max, math.max(p.submitted, math.max(p.verified, p.rejected))),
      ),
    );

    void drawSeries(int Function(CoordinatorTrendPoint p) value, Color color) {
      final Paint stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final Paint dot = Paint()..color = color;
      final Path path = Path();
      for (int i = 0; i < points.length; i++) {
        final double x = points.length == 1
            ? plot.center.dx
            : plot.left + (plot.width * i / (points.length - 1));
        final double y = plot.bottom - (value(points[i]) / maxValue) * plot.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.2, dot);
      }
      canvas.drawPath(path, stroke);
    }

    drawSeries((CoordinatorTrendPoint p) => p.submitted, const Color(0xFF0EA5E9));
    drawSeries((CoordinatorTrendPoint p) => p.verified, const Color(0xFF16A34A));
    drawSeries((CoordinatorTrendPoint p) => p.rejected, const Color(0xFFDC2626));

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final double x = points.length == 1
          ? plot.center.dx
          : plot.left + (plot.width * i / (points.length - 1));
      tp.text = TextSpan(text: points[i].label, style: DashboardTrendChartLayout.axisLabelStyle);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plot.bottom + DashboardTrendChartLayout.xLabelGap));
    }
    for (int i = 0; i <= DashboardTrendChartLayout.yAxisTickCount; i++) {
      final int value = DashboardTrendChartLayout.yAxisValue(maxValue, i);
      final double y = DashboardTrendChartLayout.yAxisLineY(plot, i);
      tp.text = TextSpan(text: '$value', style: DashboardTrendChartLayout.axisLabelStyle);
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _VerificationTrendPainter oldDelegate) => oldDelegate.points != points;
}
