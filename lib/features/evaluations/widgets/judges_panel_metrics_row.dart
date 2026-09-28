import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/status_styles.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../features/dashboard/deptadmin/services/department_dashboard_service.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../features/dashboard/deptadmin/widgets/department_metric_card.dart';

/// Reusable metric row for the judges panel screen.
class JudgesPanelMetricsRow extends StatelessWidget {
  const JudgesPanelMetricsRow({
    super.key,
    required this.judgeCount,
    required this.metrics,
    this.spacing = 10,
    this.runSpacing = 10,
  });

  final int judgeCount;
  final DepartmentDashboardAnalytics metrics;
  final double spacing;
  final double runSpacing;

  List<MetricKpiSegment> get _stripSegments => <MetricKpiSegment>[
        MetricKpiSegment.count(judgeCount, 'Judges'),
        MetricKpiSegment.count(metrics.underReviewIdeas, 'Under Review'),
        MetricKpiSegment.count(metrics.evaluatedOnlyIdeas, 'Evaluated'),
      ];

  List<DashboardMetricChipData> get _chips => <DashboardMetricChipData>[
        DepartmentMetricCard(
          value: '$judgeCount',
          label: 'Total Judges',
          icon: AppIcons.judges,
          iconBgColor: const Color(0xFFFFF4ED),
          tooltip: 'Judges assigned to this department.',
        ).toChipData(),
        DepartmentMetricCard(
          value: '${metrics.ideasSubmitted}',
          label: 'Ideas Submitted',
          icon: AppIcons.ideas,
          iconBgColor: const Color(0xFFF2EDFF),
          tooltip: 'Department idea submissions.',
        ).toChipData(),
        DepartmentMetricCard(
          value: '${metrics.underReviewIdeas}',
          label: 'Ideas Under Review',
          icon: AppIcons.clock,
          iconBgColor: const Color(0xFFEAF2FF),
          tooltip: 'Ideas currently under review.',
        ).toChipData(),
        DashboardMetricChipData.withSegments(
          label: 'Ideas',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.ideas,
          segments: <DashboardMetricChipSegment>[
            DashboardMetricChipSegment(
              icon: AppIcons.statusEvaluated,
              tooltip: 'Evaluated',
              value: '${metrics.evaluatedOnlyIdeas}',
              color: StatusStyles.evaluated,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.clock,
              tooltip: 'Under Review',
              value: '${metrics.underReviewIdeas}',
              color: StatusStyles.underReview,
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final List<MetricKpiSegment> stripSegments = ResponsiveHelper.isMobile(context)
        ? _stripSegments.where((MetricKpiSegment s) => s.label != 'Under Review').toList(growable: false)
        : _stripSegments;

    return ResponsiveListMetrics(
      spacing: spacing,
      runSpacing: runSpacing,
      chips: _chips,
      stripSegments: stripSegments,
    );
  }
}
