import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../screens/common/dashboard_components.dart';
import '../../utils/department_dashboard_service.dart';
import '../common/dashboard_trend_chart_layout.dart';
import '../common/time_frame_filter.dart';

class DepartmentTrendChart extends StatelessWidget {
  const DepartmentTrendChart({
    super.key,
    required this.points,
    required this.selectedTimeframe,
    required this.onTimeframeChanged,
  });

  final List<DepartmentTrendPoint> points;
  final DepartmentAnalyticsTimeframe selectedTimeframe;
  final ValueChanged<DepartmentAnalyticsTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = points.every((DepartmentTrendPoint p) => p.users == 0 && p.teams == 0 && p.ideas == 0 && p.evaluations == 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashboardCardHeaderRow(
          title: 'Department Participation Trend',
          icon: AppIcons.insights,
          trailing: TimeFrameFilter<DepartmentAnalyticsTimeframe>(
            options: DepartmentAnalyticsTimeframe.values,
            selected: selectedTimeframe,
            labelBuilder: (DepartmentAnalyticsTimeframe timeframe) => timeframe.label,
            onChanged: onTimeframeChanged,
          ),
        ),
        const SizedBox(height: DashboardTrendChartLayout.headerToSubtitleGap),
        Text(
          '${selectedTimeframe.label} activity across users, teams, ideas and evaluations',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: DashboardTrendChartLayout.subtitleToChartGap),
        SizedBox(
          height: DashboardTrendChartLayout.chartBoxHeight,
          child: isEmpty
              ? const Center(child: Text('No department activity data yet'))
              : CustomPaint(
                  painter: _DepartmentTrendPainter(points),
                  child: const SizedBox.expand(),
                ),
        ),
        const SizedBox(height: DashboardTrendChartLayout.chartToLegendGap),
        const Wrap(
          spacing: 12,
          runSpacing: 6,
          children: <Widget>[
            _Legend(color: Color(0xFF6A38FF), label: 'New users'),
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

class _DepartmentTrendPainter extends CustomPainter {
  _DepartmentTrendPainter(this.points);

  final List<DepartmentTrendPoint> points;

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
      points.expand((DepartmentTrendPoint p) => <int>[p.users, p.teams, p.ideas, p.evaluations]).fold<int>(0, math.max),
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

    drawSeries(points.map((DepartmentTrendPoint p) => p.users).toList(growable: false), const Color(0xFF6A38FF));
    drawSeries(points.map((DepartmentTrendPoint p) => p.teams).toList(growable: false), const Color(0xFF0EA5E9));
    drawSeries(points.map((DepartmentTrendPoint p) => p.ideas).toList(growable: false), const Color(0xFFEA580C));
    drawSeries(points.map((DepartmentTrendPoint p) => p.evaluations).toList(growable: false), const Color(0xFF16A34A));

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final double x = points.length == 1 ? plot.center.dx : plot.left + (plot.width * i / (points.length - 1));
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
  bool shouldRepaint(covariant _DepartmentTrendPainter oldDelegate) => oldDelegate.points != points;
}
