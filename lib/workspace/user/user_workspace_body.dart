import 'package:flutter/material.dart';

import '../../constants/account_workspace_visuals.dart';
import '../../constants/app_icons.dart';
import '../../models/user_model.dart';
import '../../responsive/responsive_helper.dart';
import '../../utils/common_helpers.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../core/workspace_host.dart';
import 'user_activity_section.dart';
import 'user_metadata_section.dart';
import 'user_summary_section.dart';
import 'user_workspace_loader.dart';

class UserWorkspaceBody extends StatefulWidget {
  const UserWorkspaceBody({super.key, required this.vm});

  final UserWorkspaceViewModel vm;

  @override
  State<UserWorkspaceBody> createState() => _UserWorkspaceBodyState();
}

class _UserWorkspaceBodyState extends State<UserWorkspaceBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final UserModel u = widget.vm.user;
      final String subtitle = _headerSubtitle(u);
      HkzWorkspace.updateMessage(
        context,
        title: userDisplayName(u),
        subtitle: subtitle,
      );
    });
  }

  String _headerSubtitle(UserModel u) {
    final String dept = u.department.trim().isEmpty ? u.departmentCode.trim() : u.department.trim();
    final String status = AccountWorkspaceVisuals.userStatusDisplayLabel(u.status);
    if (dept.isEmpty) return status;
    return '$dept · $status';
  }

  @override
  Widget build(BuildContext context) {
    final UserWorkspaceViewModel vm = widget.vm;
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

    return Scrollbar(
      child: ListView(
        padding: pad,
        children: <Widget>[
          UserSummarySection(
            user: vm.user,
            organizationName: vm.organizationName,
          ),
          if (vm.user.orgId.trim().isEmpty) ...<Widget>[
            const SizedBox(height: 12),
            const Text(
              'This profile is not linked to an organization in Hackz, so activity counts are unavailable.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), height: 1.35),
            ),
          ] else ...<Widget>[
            const SizedBox(height: 16),
            DashboardMetricChipGrid(chips: chips),
          ],
          const SizedBox(height: 20),
          UserMetadataSection(vm: vm),
          const SizedBox(height: 20),
          UserActivitySection(items: vm.recentActivity),
        ],
      ),
    );
  }
}
