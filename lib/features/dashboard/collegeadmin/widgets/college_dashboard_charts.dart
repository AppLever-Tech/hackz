import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_columns.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/common/dashboard_trend_chart_layout.dart';
import '../../../../core/ui/common/time_frame_filter.dart';
import '../../chrome/dashboard_components.dart';
import '../../deptadmin/services/department_dashboard_service.dart';
import '../services/college_dashboard_analytics.dart';

enum CollegeChartRowLayout { balanced, deptExpanded, ideaExpanded }

class CollegeChartsSection extends StatelessWidget {
  const CollegeChartsSection({
    super.key,
    required this.deptData,
    required this.ideaPoints,
    required this.timeframe,
    required this.onTimeframeChanged,
    required this.layout,
    required this.onLayoutChanged,
  });

  final CollegeDepartmentComparison deptData;
  final List<CollegeTrendPoint> ideaPoints;
  final DepartmentAnalyticsTimeframe timeframe;
  final ValueChanged<DepartmentAnalyticsTimeframe> onTimeframeChanged;
  final CollegeChartRowLayout layout;
  final ValueChanged<CollegeChartRowLayout> onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final int firstFlex;
    final int secondFlex;
    switch (layout) {
      case CollegeChartRowLayout.balanced:
        firstFlex = 1;
        secondFlex = 1;
      case CollegeChartRowLayout.deptExpanded:
        firstFlex = 9;
        secondFlex = 1;
      case CollegeChartRowLayout.ideaExpanded:
        firstFlex = 1;
        secondFlex = 9;
    }

    final bool compact = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ChartToolbar(
          timeframe: timeframe,
          onTimeframeChanged: onTimeframeChanged,
        ),
        const SizedBox(height: 10),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CollegeDepartmentComparisonChart(
                data: deptData,
                timeframeLabel: timeframe.label,
                expandTrailing: _ExpandChip(
                  tooltip: 'Widen problems vs ideas chart',
                  selected: layout == CollegeChartRowLayout.deptExpanded,
                  onTap: () => onLayoutChanged(
                    layout == CollegeChartRowLayout.deptExpanded
                        ? CollegeChartRowLayout.balanced
                        : CollegeChartRowLayout.deptExpanded,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CollegeIdeaActivityChart(
                points: ideaPoints,
                timeframeLabel: timeframe.label,
                expandTrailing: _ExpandChip(
                  tooltip: 'Widen idea activity chart',
                  selected: layout == CollegeChartRowLayout.ideaExpanded,
                  onTap: () => onLayoutChanged(
                    layout == CollegeChartRowLayout.ideaExpanded
                        ? CollegeChartRowLayout.balanced
                        : CollegeChartRowLayout.ideaExpanded,
                  ),
                ),
              ),
            ],
          )
        else
          ResponsivePair(
            firstFlex: firstFlex,
            secondFlex: secondFlex,
            crossAxisAlignment: CrossAxisAlignment.start,
            first: CollegeDepartmentComparisonChart(
              data: deptData,
              timeframeLabel: timeframe.label,
              expandTrailing: _ExpandChip(
                tooltip: 'Widen problems vs ideas chart',
                selected: layout == CollegeChartRowLayout.deptExpanded,
                onTap: () => onLayoutChanged(
                  layout == CollegeChartRowLayout.deptExpanded
                      ? CollegeChartRowLayout.balanced
                      : CollegeChartRowLayout.deptExpanded,
                ),
              ),
            ),
            second: CollegeIdeaActivityChart(
              points: ideaPoints,
              timeframeLabel: timeframe.label,
              expandTrailing: _ExpandChip(
                tooltip: 'Widen idea activity chart',
                selected: layout == CollegeChartRowLayout.ideaExpanded,
                onTap: () => onLayoutChanged(
                  layout == CollegeChartRowLayout.ideaExpanded
                      ? CollegeChartRowLayout.balanced
                      : CollegeChartRowLayout.ideaExpanded,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChartToolbar extends StatelessWidget {
  const _ChartToolbar({
    required this.timeframe,
    required this.onTimeframeChanged,
  });

  final DepartmentAnalyticsTimeframe timeframe;
  final ValueChanged<DepartmentAnalyticsTimeframe> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    final Widget filter = TimeFrameFilter<DepartmentAnalyticsTimeframe>(
      options: DepartmentAnalyticsTimeframe.values,
      selected: timeframe,
      labelBuilder: (DepartmentAnalyticsTimeframe option) => option.label,
      onChanged: onTimeframeChanged,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Expanded(
          flex: 2,
          child: Text(
            'Charts',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ),
        Expanded(
          flex: 5,
          child: Align(
            alignment: Alignment.centerRight,
            child: filter,
          ),
        ),
      ],
    );
  }
}

class _ExpandChip extends StatelessWidget {
  const _ExpandChip({
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Icon(
              selected ? Icons.fullscreen_exit : Icons.fullscreen,
              size: 14,
              color: selected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class CollegeDepartmentComparisonChart extends StatelessWidget {
  const CollegeDepartmentComparisonChart({
    super.key,
    required this.data,
    required this.timeframeLabel,
    this.expandTrailing,
  });

  final CollegeDepartmentComparison data;
  final String timeframeLabel;
  final Widget? expandTrailing;

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Department-wise Problems vs Ideas',
      icon: AppIcons.departments,
      trailing: expandTrailing,
      compactHeaderTrailing: expandTrailing != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '$timeframeLabel · by department',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: DashboardTrendChartLayout.subtitleToChartGap),
          SizedBox(
            height: DashboardTrendChartLayout.chartBoxHeight,
            child: data.isEmpty || data.labels.isEmpty
                ? const Center(
                    child: Text(
                      'No department activity in this period',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                    ),
                  )
                : CustomPaint(
                    painter: _DepartmentComparisonPainter(
                      labels: data.labels,
                      ideas: data.ideas,
                      problems: data.problems,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: DashboardTrendChartLayout.chartToLegendGap),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              _LegendDot(color: Color(0xFF6A38FF), label: 'Ideas'),
              _LegendDot(color: Color(0xFF0EA5E9), label: 'Problems'),
            ],
          ),
        ],
      ),
    );
  }
}

class CollegeIdeaActivityChart extends StatelessWidget {
  const CollegeIdeaActivityChart({
    super.key,
    required this.points,
    required this.timeframeLabel,
    this.expandTrailing,
  });

  final List<CollegeTrendPoint> points;
  final String timeframeLabel;
  final Widget? expandTrailing;

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = points.every((CollegeTrendPoint p) => p.count == 0);
    final int nonZero = points.where((CollegeTrendPoint p) => p.count > 0).length;

    return ChartCard(
      title: 'Idea Activity',
      icon: AppIcons.ideas,
      trailing: expandTrailing,
      compactHeaderTrailing: expandTrailing != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '$timeframeLabel · ideas submitted',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: DashboardTrendChartLayout.subtitleToChartGap),
          SizedBox(
            height: DashboardTrendChartLayout.chartBoxHeight,
            child: isEmpty
                ? const Center(
                    child: Text(
                      'No ideas submitted in this period',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                    ),
                  )
                : CustomPaint(
                    painter: _IdeaTrendPainter(
                      labels: points.map((CollegeTrendPoint p) => p.label).toList(growable: false),
                      counts: points.map((CollegeTrendPoint p) => p.count).toList(growable: false),
                      sparse: nonZero <= 1,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: DashboardTrendChartLayout.chartToLegendGap),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              _LegendDot(color: Color(0xFF6A38FF), label: 'Ideas submitted'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DepartmentComparisonPainter extends CustomPainter {
  _DepartmentComparisonPainter({
    required this.labels,
    required this.ideas,
    required this.problems,
  });

  final List<String> labels;
  final List<int> ideas;
  final List<int> problems;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 34;
    const double rightPad = 8;
    const double topPad = 8;
    const double bottomPad = 36;
    final Rect rect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );
    final int count = labels.length;
    if (count == 0) return;

    final int maxValue = <int>[...ideas, ...problems].fold<int>(1, (int a, int b) => a > b ? a : b);
    final TextStyle labelStyle = TextStyle(color: Colors.grey.shade700, fontSize: 10);

    final Paint grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = rect.top + (rect.height * i / 4);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
      final int tick = (maxValue * (4 - i) / 4).round();
      final TextPainter tp = TextPainter(
        text: TextSpan(text: '$tick', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y - tp.height / 2));
    }

    final double groupWidth = rect.width / count;
    final double barWidth = (groupWidth * 0.28).clamp(4.0, 18.0);

    for (int i = 0; i < count; i++) {
      final double cx = rect.left + groupWidth * (i + 0.5);
      final int ideaVal = i < ideas.length ? ideas[i] : 0;
      final int problemVal = i < problems.length ? problems[i] : 0;

      _drawBar(canvas, cx - barWidth * 0.55, barWidth, rect.bottom, rect.height, ideaVal, maxValue, const Color(0xFF6A38FF));
      _drawBar(canvas, cx + barWidth * 0.55, barWidth, rect.bottom, rect.height, problemVal, maxValue, const Color(0xFF0EA5E9));

      final TextPainter xLabel = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: groupWidth - 4);
      xLabel.paint(canvas, Offset(cx - xLabel.width / 2, rect.bottom + 4));
    }
  }

  void _drawBar(
    Canvas canvas,
    double centerX,
    double width,
    double bottom,
    double height,
    int value,
    int maxValue,
    Color color,
  ) {
    final double barHeight = maxValue == 0 ? 0 : (value / maxValue) * height;
    final Rect bar = Rect.fromLTWH(centerX - width / 2, bottom - barHeight, width, barHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(4)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _DepartmentComparisonPainter oldDelegate) =>
      oldDelegate.labels != labels || oldDelegate.ideas != ideas || oldDelegate.problems != problems;
}

class _IdeaTrendPainter extends CustomPainter {
  _IdeaTrendPainter({
    required this.labels,
    required this.counts,
    required this.sparse,
  });

  final List<String> labels;
  final List<int> counts;
  final bool sparse;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 34;
    const double rightPad = 8;
    const double topPad = 8;
    const double bottomPad = 28;
    final Rect chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    final TextStyle labelStyle = TextStyle(color: Colors.grey.shade700, fontSize: 10);
    final int maxValue = counts.fold<int>(1, (int m, int v) => v > m ? v : m);

    final Paint grid = Paint()
      ..color = const Color(0xFFE8ECF6)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final double y = chartRect.bottom - (chartRect.height * i / 4);
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), grid);
      final TextPainter yLabel = TextPainter(
        text: TextSpan(text: '${(maxValue * i / 4).round()}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      yLabel.paint(canvas, Offset(4, y - yLabel.height / 2));
    }

    if (counts.isEmpty) return;

    if (sparse) {
      for (int i = 0; i < counts.length; i++) {
        if (counts[i] <= 0) continue;
        final double t = counts.length == 1 ? 0.5 : i / (counts.length - 1);
        final double x = chartRect.left + chartRect.width * t;
        final double h = (counts[i] / maxValue) * chartRect.height;
        final Rect bar = Rect.fromLTWH(x - 8, chartRect.bottom - h, 16, h);
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar, const Radius.circular(4)),
          Paint()..color = const Color(0xFF6A38FF),
        );
      }
    } else {
      final Paint line = Paint()
        ..color = const Color(0xFF6A38FF)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke;
      final Paint dot = Paint()..color = const Color(0xFF6A38FF);
      final Path path = Path();
      for (int i = 0; i < counts.length; i++) {
        final double t = counts.length == 1 ? 0.5 : i / (counts.length - 1);
        final double x = chartRect.left + chartRect.width * t;
        final double y = chartRect.bottom - ((counts[i] / maxValue) * chartRect.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.5, dot);
      }
      canvas.drawPath(path, line);
    }

    final int labelStep = labels.length <= 6 ? 1 : (labels.length / 6).ceil();
    for (int i = 0; i < labels.length; i++) {
      if (i % labelStep != 0 && i != labels.length - 1) continue;
      final double t = labels.length == 1 ? 0.5 : i / (labels.length - 1);
      final double x = chartRect.left + chartRect.width * t;
      final TextPainter xLabel = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 52);
      xLabel.paint(canvas, Offset(x - xLabel.width / 2, chartRect.bottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _IdeaTrendPainter oldDelegate) =>
      oldDelegate.labels != labels || oldDelegate.counts != counts || oldDelegate.sparse != sparse;
}
