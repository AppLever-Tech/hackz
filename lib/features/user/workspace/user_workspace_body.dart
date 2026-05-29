import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import 'user_activity_section.dart';
import 'user_metadata_section.dart';
import 'user_summary_section.dart';
import 'user_workspace_loader.dart';

class UserWorkspaceBody extends StatelessWidget {
  const UserWorkspaceBody({super.key, required this.vm});

  final UserWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final UserWorkspaceViewModel vm = this.vm;
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      12,
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      28,
    );

    final List<DashboardMetricChipData> chips = <DashboardMetricChipData>[
      DashboardMetricChipData.single(
        label: 'Teams',
        value: '${vm.teamLinksCount}',
        color: dashboardMetricAccentFromIconBg(const Color(0xFFEAF2FF)),
        icon: AppIcons.teams,
        tooltip: 'Teams linked as mentor or member within this organization.',
      ),
      DashboardMetricChipData.single(
        label: 'Ideas',
        value: '${vm.submittedIdeasCount}',
        color: dashboardMetricAccentFromIconBg(const Color(0xFFFFF4E8)),
        icon: AppIcons.ideas,
        tooltip: 'Ideas created by this user in this organization.',
      ),
      DashboardMetricChipData.single(
        label: 'Evaluations',
        value: '${vm.evaluationCount}',
        color: dashboardMetricAccentFromIconBg(const Color(0xFFF2EDFF)),
        icon: AppIcons.scoring,
        tooltip: 'Judge score records attributed to this user in this organization.',
      ),
    ];

    return ListView(
      padding: pad,
      children: <Widget>[
        UserSummarySection(user: vm.user, organizationName: vm.organizationName),
        const SizedBox(height: 14),
        DashboardMetricChipGrid(spacing: 10, runSpacing: 10, chips: chips),
        const SizedBox(height: 14),
        UserMetadataSection(vm: vm),
        const SizedBox(height: 14),
        UserActivitySection(items: vm.recentActivity),
      ],
    );
  }
}
