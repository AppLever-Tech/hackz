import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import 'team_activity_section.dart';
import 'team_ideas_section.dart';
import 'team_members_section.dart';
import 'team_metrics_section.dart';
import 'team_summary_section.dart';
import 'team_workspace_loader.dart';

class TeamWorkspaceBody extends StatelessWidget {
  const TeamWorkspaceBody({super.key, required this.vm});

  final TeamWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final vm = this.vm;
    final EdgeInsets pad = EdgeInsets.fromLTRB(
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      12,
      ResponsiveHelper.isMobile(context) ? 14 : 16,
      28,
    );

    return ListView(
      padding: pad,
      children: <Widget>[
        TeamSummarySection(vm: vm),
        const SizedBox(height: 14),
        TeamMembersSection(vm: vm),
        const SizedBox(height: 14),
        TeamMetricsSection(vm: vm),
        const SizedBox(height: 14),
        TeamIdeasSection(vm: vm),
        const SizedBox(height: 14),
        TeamActivitySection(items: vm.recentActivity),
      ],
    );
  }
}
