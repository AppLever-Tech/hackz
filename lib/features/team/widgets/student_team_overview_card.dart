import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/enums/team_status.dart';
import '../../user/models/user_model.dart';
import '../../../utils/common_helpers.dart' show formatDateTime, sortUsersByDisplayName;
import '../../../utils/student_dashboard_service.dart';
import '../../../screens/common/dashboard_components.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/widgets/common/context_pill.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';

/// Student dashboard team panel — layout aligned with faculty [TeamWorkspaceCard].
class StudentTeamOverviewCard extends StatelessWidget {
  const StudentTeamOverviewCard({
    super.key,
    required this.vm,
    this.compact = false,
  });

  final StudentDashboardVm vm;
  final bool compact;

  double get _rowGap => compact ? 6 : 8;

  @override
  Widget build(BuildContext context) {
    final Widget body = vm.team.teamId.isEmpty
        ? const Text('No team assigned yet.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
        : _teamContent(context);

    return SectionContainer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool boundedHeight = constraints.maxHeight.isFinite;
          final Widget bodySlot = boundedHeight && compact
              ? Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: body,
                  ),
                )
              : compact
                  ? body
                  : Expanded(child: body);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const DashboardCardTitle(title: 'My Team', icon: AppIcons.teams),
              const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
              bodySlot,
            ],
          );
        },
      ),
    );
  }

  Widget _teamContent(BuildContext context) {
    final List<UserModel> members = sortUsersByDisplayName(vm.teamMembers);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildTeamNameRow(context),
        SizedBox(height: _rowGap),
        _buildMentorRow(context),
        SizedBox(height: _rowGap),
        _buildStudentsRow(context, members),
        SizedBox(height: _rowGap),
        _buildMetricsRow(),
      ],
    );
  }

  Widget _buildTeamNameRow(BuildContext context) {
    final String name = vm.team.teamName.trim().isEmpty ? '—' : vm.team.teamName.trim();
    final String teamId = vm.team.teamId.trim();
    if (teamId.isEmpty) {
      return Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: ContextPill(
        label: name,
        semantic: ContextPillSemantic.team,
        onTap: () => WorkspaceNavigator.openTeam(context, teamId),
        compact: true,
      ),
    );
  }

  Widget _buildMentorRow(BuildContext context) {
    final String name = vm.mentorName.trim().isEmpty ? '—' : vm.mentorName.trim();
    if (vm.mentorId.trim().isEmpty) {
      return _plainLabel(name, AppIcons.faculty);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: ContextPill(
        label: name,
        semantic: ContextPillSemantic.user,
        icon: AppIcons.faculty,
        onTap: () => WorkspaceNavigator.openUser(context, vm.mentorId),
        compact: true,
      ),
    );
  }

  Widget _buildStudentsRow(BuildContext context, List<UserModel> members) {
    if (members.isEmpty) {
      return const Text('No students on team', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: members
          .map((UserModel member) => _memberPill(context, member))
          .toList(growable: false),
    );
  }

  Widget _buildMetricsRow() {
    final TeamStatus status = vm.team.status;
    final Color statusColor = switch (status) {
      TeamStatus.active => const Color(0xFF177C50),
      TeamStatus.inactive => const Color(0xFFB93838),
      TeamStatus.locked => const Color(0xFFB56A11),
    };
    final int ideaCount = vm.ideaCards.length;

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _metricLine(AppIcons.ideas, '$ideaCount idea${ideaCount == 1 ? '' : 's'}'),
        _metricLine(AppIcons.statusActive, 'Team status: ${status.value}', color: statusColor),
        _metricLine(AppIcons.clock, 'Created ${formatDateTime(vm.team.createdAt)}'),
      ],
    );
  }

  Widget _memberPill(BuildContext context, UserModel member) {
    final String name = '${member.firstName} ${member.lastName}'.trim();
    final String label = name.isEmpty ? member.userId : name;
    if (member.userId.trim().isEmpty) {
      return _plainLabel(label, AppIcons.forUserRoleCode(member.role));
    }
    return ContextPill(
      label: label,
      semantic: ContextPillSemantic.user,
      icon: AppIcons.forUserRoleCode(member.role),
      onTap: () => WorkspaceNavigator.openUser(context, member.userId),
      compact: true,
    );
  }

  Widget _plainLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      ],
    );
  }

  Widget _metricLine(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
