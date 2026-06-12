import 'package:flutter/material.dart';

import '../../utils/department_dashboard_service.dart';
import '../../core/ui/common/dashboard_card/dashboard_card_layout.dart';

class UserDistributionWidget extends StatelessWidget {
  const UserDistributionWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.segments,
  });

  final String title;
  final String subtitle;
  final List<DepartmentDistributionSegment> segments;

  @override
  Widget build(BuildContext context) {
    return DashboardDistributionCard(
      title: title,
      subtitle: subtitle,
      variant: DashboardDonutVariant.department,
      segments: segments
          .map(
            (DepartmentDistributionSegment segment) => DashboardDonutSegment(
              label: segment.label,
              count: segment.count,
              color: segment.color,
              icon: segment.icon,
            ),
          )
          .toList(growable: false),
    );
  }
}
