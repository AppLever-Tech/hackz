import 'package:flutter/material.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../org_admin_primary_menu.dart';
import '../services/tenant_setup_readiness_service.dart';
import '../../chrome/dashboard_components.dart';

class _SnapshotMetric {
  const _SnapshotMetric({required this.data, required this.menuIndex});

  final DashboardMetricChipData data;
  final int menuIndex;
}

class OrgAdminOperationalSnapshot extends StatelessWidget {
  const OrgAdminOperationalSnapshot({
    super.key,
    required this.counts,
    required this.onNavigateToModule,
  });

  final TenantOperationalCounts counts;
  final ValueChanged<int> onNavigateToModule;

  List<_SnapshotMetric> get _metrics => <_SnapshotMetric>[
        _SnapshotMetric(
          data: DashboardMetricChipData.single(
            label: 'Departments',
            value: '${counts.departments}',
            color: const Color(0xFF4A67FF),
            icon: AppIcons.departments,
          ),
          menuIndex: OrgAdminPrimaryMenu.manageCollege,
        ),
        _SnapshotMetric(
          data: DashboardMetricChipData.single(
            label: 'Teams',
            value: '${counts.teams}',
            color: const Color(0xFF0EA5E9),
            icon: AppIcons.teams,
          ),
          menuIndex: OrgAdminPrimaryMenu.manageCollege,
        ),
        _SnapshotMetric(
          data: DashboardMetricChipData.single(
            label: 'Problems',
            value: '${counts.problems}',
            color: const Color(0xFF059669),
            icon: AppIcons.problems,
          ),
          menuIndex: OrgAdminPrimaryMenu.problemStatements,
        ),
        _SnapshotMetric(
          data: DashboardMetricChipData.single(
            label: 'Active events',
            value: '${counts.activeEvents}',
            color: const Color(0xFF7C3AED),
            icon: AppIcons.event,
          ),
          menuIndex: OrgAdminPrimaryMenu.events,
        ),
      ];

  int _columnCount(BuildContext context, int chipCount, double maxWidth, double gap) {
    if (chipCount == 0) return 1;
    const double minChipWidth = 118;
    const int desktopMax = 4;
    final int desired = ResponsiveHelper.isDesktopOrWider(context)
        ? (chipCount < desktopMax ? chipCount : desktopMax)
        : (chipCount < 2 ? chipCount : 2);
    if (!maxWidth.isFinite || maxWidth <= 0) return desired;
    final int fit = ((maxWidth + gap) / (minChipWidth + gap)).floor().clamp(1, chipCount);
    return fit < desired ? fit : desired;
  }

  @override
  Widget build(BuildContext context) {
    final List<_SnapshotMetric> metrics = _metrics;
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const DashboardCardTitle(title: 'Operational snapshot', icon: AppIcons.insights),
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double gap = ResponsiveHelper.metricGridSpacing(context);
              final int columns = _columnCount(context, metrics.length, constraints.maxWidth, gap);
              final double tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: metrics
                    .map(
                      (_SnapshotMetric metric) => SizedBox(
                        width: tileWidth,
                        child: OrgAdminMetricChipTile(
                          data: metric.data,
                          onTap: () => onNavigateToModule(metric.menuIndex),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class OrgAdminMetricChipTile extends StatelessWidget {
  const OrgAdminMetricChipTile({
    super.key,
    required this.data,
    required this.onTap,
  });

  final DashboardMetricChipData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DashboardMetricChip(data: data),
      ),
    );
  }
}
