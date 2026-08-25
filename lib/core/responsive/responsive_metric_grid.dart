import 'package:flutter/material.dart';

import '../ui/dashboard/dashboard_metric_chips.dart';
import 'responsive_helper.dart';

/// Responsive metric chips: 2 per row on mobile/tablet, 4 on desktop.
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.chips,
    this.spacing,
    this.runSpacing,
    this.maxDesktopColumns,
    this.compact = false,
  });

  final List<DashboardMetricChipData> chips;
  final double? spacing;
  final double? runSpacing;
  final int? maxDesktopColumns;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DashboardMetricChipGrid(
      chips: chips,
      spacing: spacing,
      runSpacing: runSpacing,
      maxDesktopColumns: maxDesktopColumns,
      compact: compact,
    );
  }
}

/// One `125 Ideas` segment inside [ResponsiveMetricKpiStrip].
class MetricKpiSegment {
  const MetricKpiSegment({
    required this.value,
    required this.label,
  });

  MetricKpiSegment.count(int count, this.label) : value = '$count';

  final String value;
  final String label;
}

/// Compact text KPI strip for mobile list/management screens.
///
/// Renders equal-width centered columns with value and label on one line.
abstract final class MetricKpiStripStyles {
  MetricKpiStripStyles._();

  static const double segmentGap = 6;

  static const TextStyle value = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Color(0xFF0F172A),
    height: 1.2,
    letterSpacing: -0.2,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
    height: 1.2,
  );
}

/// One centered KPI cell inside [ResponsiveMetricKpiStrip].
class MetricKpiSegmentCell extends StatelessWidget {
  const MetricKpiSegmentCell({super.key, required this.segment});

  final MetricKpiSegment segment;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(text: '${segment.value} ', style: MetricKpiStripStyles.value),
            TextSpan(text: segment.label, style: MetricKpiStripStyles.label),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Horizontally centered mobile KPI strip with uniform spacing between segments.
class ResponsiveMetricKpiStrip extends StatelessWidget {
  const ResponsiveMetricKpiStrip({
    super.key,
    required this.segments,
    this.gap = MetricKpiStripStyles.segmentGap,
  });

  final List<MetricKpiSegment> segments;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < segments.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: gap),
          Expanded(child: MetricKpiSegmentCell(segment: segments[i])),
        ],
      ],
    );
  }
}

/// List/management screens: text KPI strip on mobile, metric grid elsewhere.
class ResponsiveListMetrics extends StatelessWidget {
  const ResponsiveListMetrics({
    super.key,
    required this.chips,
    required this.stripSegments,
    this.spacing,
    this.runSpacing,
  });

  final List<DashboardMetricChipData> chips;
  final List<MetricKpiSegment> stripSegments;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return ResponsiveMetricKpiStrip(segments: stripSegments);
    }

    return ResponsiveMetricGrid(
      chips: chips,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }
}
