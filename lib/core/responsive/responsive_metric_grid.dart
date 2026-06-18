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
  });

  final List<DashboardMetricChipData> chips;
  final double? spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    return DashboardMetricChipGrid(
      chips: chips,
      spacing: spacing,
      runSpacing: runSpacing,
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
/// Example: `125 Ideas • 80 Approved • 20 Pending • 10 Rejected`
abstract final class MetricKpiStripStyles {
  MetricKpiStripStyles._();

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
  static const TextStyle separator = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Color(0xFFCBD5E1),
    height: 1.2,
  );
}

class ResponsiveMetricKpiStrip extends StatelessWidget {
  const ResponsiveMetricKpiStrip({
    super.key,
    required this.segments,
  });

  final List<MetricKpiSegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            for (int i = 0; i < segments.length; i++) ...<InlineSpan>[
              if (i > 0) const TextSpan(text: ' • ', style: MetricKpiStripStyles.separator),
              TextSpan(
                text: '${segments[i].value} ',
                style: MetricKpiStripStyles.value,
              ),
              TextSpan(
                text: segments[i].label,
                style: MetricKpiStripStyles.label,
              ),
            ],
          ],
        ),
        maxLines: 1,
      ),
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
