import 'package:flutter/material.dart';

/// Shared layout metrics for dashboard multi-series line trend charts.
abstract final class DashboardTrendChartLayout {
  DashboardTrendChartLayout._();

  /// Intervals between y-axis ticks (4 → five horizontal grid lines).
  static const int yAxisTickCount = 4;

  /// Vertical distance between adjacent y-axis tick labels and grid lines.
  static const double yAxisTickSpacing = 28;

  /// Space between subtitle text and the chart plot.
  static const double subtitleToChartGap = 20;

  /// Space between the chart plot and the color legend row.
  static const double chartToLegendGap = 10;

  /// Plot area height derived from [yAxisTickSpacing] × [yAxisTickCount].
  static double get plotHeight => yAxisTickSpacing * yAxisTickCount;

  /// Total painted chart box height (plot + padding).
  static double get chartBoxHeight => plotTop + plotHeight + plotBottom;

  /// Dashboard card header row (matches [TimeFrameFilter.barHeight]).
  static const double cardHeaderRowHeight = 20;

  static const double headerToSubtitleGap = 4;

  /// Title stacked above timeframe filter on narrow cards ([DashboardCardHeaderRow]).
  static const double stackedHeaderBlockHeight =
      cardHeaderRowHeight + headerToSubtitleGap + cardHeaderRowHeight;

  /// Approximate single-line subtitle height at 12px.
  static const double subtitleLineEstimate = 16;

  /// Legend [Wrap] height when chips wrap to two rows in a narrow panel.
  static const double legendRowEstimate = 34;

  /// Small safety margin for font metrics and device rounding.
  static const double trendCardHeightBuffer = 4;

  /// Minimum panel body height for a trend chart card (header through legend).
  static double get trendCardContentHeight =>
      stackedHeaderBlockHeight +
      headerToSubtitleGap +
      subtitleLineEstimate +
      subtitleToChartGap +
      chartBoxHeight +
      chartToLegendGap +
      legendRowEstimate +
      trendCardHeightBuffer;

  static const double plotLeft = 34;
  static const double plotRight = 10;
  static const double plotTop = 8;
  static const double plotBottom = 18;

  static const double xLabelGap = 6;

  static const TextStyle axisLabelStyle = TextStyle(fontSize: 10, color: Color(0xFF64748B));

  static Rect plotRect(Size size) {
    return Rect.fromLTWH(
      plotLeft,
      plotTop,
      size.width - plotLeft - plotRight,
      plotHeight,
    );
  }

  static double yAxisLineY(Rect plot, int tickIndex) {
    return plot.top + yAxisTickSpacing * tickIndex;
  }

  static int yAxisValue(int maxValue, int tickIndex) {
    return (maxValue * (yAxisTickCount - tickIndex) / yAxisTickCount).round();
  }
}
