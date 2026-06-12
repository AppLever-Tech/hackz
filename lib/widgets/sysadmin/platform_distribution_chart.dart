import 'package:flutter/material.dart';

import '../../utils/sysadmin_dashboard_service.dart';
import '../../core/ui/common/dashboard_card/dashboard_card_layout.dart';

class PlatformDistributionChart extends StatelessWidget {
  const PlatformDistributionChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.segments,
    this.centerLabel,
  });

  final String title;
  final String subtitle;
  final List<PlatformDistributionSegment> segments;
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    return DashboardDistributionCard(
      title: title,
      subtitle: subtitle,
      centerLabel: centerLabel,
      subtitleColor: Colors.grey.shade600,
      variant: DashboardDonutVariant.platform,
      segments: segments
          .map(
            (PlatformDistributionSegment s) => DashboardDonutSegment(
              label: s.label,
              count: s.count,
              color: s.color,
            ),
          )
          .toList(growable: false),
    );
  }
}
