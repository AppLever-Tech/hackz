import 'package:flutter/material.dart';

import '../../requests/widgets/team_change_history_timeline.dart';
import '../../../core/workspace/workspace_theme.dart';
import 'team_activity_section.dart';
import 'team_ideas_section.dart';
import 'team_members_section.dart';
import 'team_summary_section.dart';
import 'team_workspace_loader.dart';

class TeamWorkspaceBody extends StatelessWidget {
  const TeamWorkspaceBody({super.key, required this.vm});

  final TeamWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final vm = this.vm;
    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        TeamSummarySection(vm: vm),
        const SizedBox(height: 14),
        TeamMembersSection(vm: vm),
        const SizedBox(height: 14),
        TeamIdeasSection(vm: vm),
        const SizedBox(height: 14),
        TeamActivitySection(items: vm.recentActivity),
        const SizedBox(height: 14),
        TeamChangeHistoryTimeline(teamId: vm.team.teamId),
      ],
    );
  }
}
