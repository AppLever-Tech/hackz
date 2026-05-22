import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../models/user_model.dart';
import '../utils/student_dashboard_service.dart';
import '../screens/common/dashboard_components.dart';
import 'common/entity_card_pills.dart';
import '../workspace/workspace.dart';

class StudentTeamOverviewCard extends StatelessWidget {
  const StudentTeamOverviewCard({
    super.key,
    required this.vm,
  });

  final StudentDashboardVm vm;

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const DashboardCardTitle(title: 'My Team Overview', icon: AppIcons.teams),
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
          if (vm.team.teamId.isEmpty)
            _emptyState('No team assigned yet.')
          else
            _overviewContent(context),
        ],
      ),
    );
  }

  Widget _overviewContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _teamPill(context),
        const SizedBox(height: 8),
        _mentorPill(context),
        const SizedBox(height: 8),
        _memberPills(context),
        const SizedBox(height: 8),
        _ideaPills(context),
      ],
    );
  }

  Widget _teamPill(BuildContext context) {
    final String teamName = vm.team.teamName.trim().isEmpty ? '—' : vm.team.teamName.trim();
    if (vm.team.teamId.trim().isEmpty) {
      return EntityCardPills.plainValue(teamName);
    }
    return EntityCardPills.workspace(
      teamName,
      ContextPillSemantic.team,
      () => WorkspaceNavigator.openTeam(context, vm.team.teamId),
      fullWidth: true,
      icon: AppIcons.teams,
    );
  }

  Widget _mentorPill(BuildContext context) {
    final String name = vm.mentorName.trim().isEmpty ? '—' : vm.mentorName.trim();
    if (vm.mentorId.trim().isEmpty) {
      return EntityCardPills.plainValue(name);
    }
    return EntityCardPills.workspace(
      name,
      ContextPillSemantic.user,
      () => WorkspaceNavigator.openUser(context, vm.mentorId),
      fullWidth: true,
      icon: AppIcons.faculty,
    );
  }

  Widget _memberPills(BuildContext context) {
    if (vm.teamMembers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vm.teamMembers
          .map((UserModel member) => _memberPill(context, member))
          .toList(growable: false),
    );
  }

  Widget _ideaPills(BuildContext context) {
    if (vm.ideaCards.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: vm.ideaCards.map((item) {
        final String title = item.idea.ideaTitle.trim().isEmpty
            ? 'Untitled Idea'
            : item.idea.ideaTitle.trim();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: item.idea.ideaId.trim().isEmpty
              ? EntityCardPills.plainValue(title)
              : EntityCardPills.workspace(
                  title,
                  ContextPillSemantic.idea,
                  () => WorkspaceNavigator.openIdea(context, item.idea.ideaId),
                  fullWidth: true,
                  icon: AppIcons.ideas,
                ),
        );
      }).toList(growable: false),
    );
  }

  Widget _memberPill(BuildContext context, UserModel member) {
    final String name = '${member.firstName} ${member.lastName}'.trim();
    final String label = name.isEmpty ? member.userId : name;
    if (member.userId.trim().isEmpty) {
      return EntityCardPills.plainValue(label);
    }
    return EntityCardPills.workspace(
      label,
      ContextPillSemantic.user,
      () => WorkspaceNavigator.openUser(context, member.userId),
      icon: AppIcons.forUserRoleCode(member.role),
    );
  }

  Widget _emptyState(String text) {
    return Text(text, style: const TextStyle(color: Color(0xFF5B628A)));
  }
}
