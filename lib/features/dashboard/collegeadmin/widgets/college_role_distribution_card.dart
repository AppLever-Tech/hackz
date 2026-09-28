import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../services/college_dashboard_analytics.dart';

class CollegeRoleDistributionCard extends StatelessWidget {
  const CollegeRoleDistributionCard({super.key, required this.metrics});

  final CollegeRoleMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget card = DashboardDistributionCard(
          title: 'People by role',
          subtitle: 'Across all departments',
          variant: DashboardDonutVariant.department,
          segments: <DashboardDonutSegment>[
            DashboardDonutSegment(
              label: 'Dept admins',
              count: metrics.departmentAdmins,
              color: const Color(0xFF4338CA),
              icon: AppIcons.adminProfile,
            ),
            DashboardDonutSegment(
              label: 'Coordinators',
              count: metrics.coordinators,
              color: const Color(0xFF2563EB),
              icon: AppIcons.coordinator,
            ),
            DashboardDonutSegment(
              label: 'Judges',
              count: metrics.judges,
              color: const Color(0xFFEA580C),
              icon: AppIcons.judges,
            ),
            DashboardDonutSegment(
              label: 'Team members',
              count: metrics.teamMembers,
              color: const Color(0xFF16A34A),
              icon: AppIcons.teamMember,
            ),
          ],
        );
        if (!constraints.maxHeight.isFinite) {
          return card;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[Expanded(child: card)],
        );
      },
    );
  }
}
