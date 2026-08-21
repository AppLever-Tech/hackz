import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../user/models/user_model.dart';
import '../models/enums/team_status.dart';
import '../../../utils/common_helpers.dart' show formatDateTime, sortUsersByDisplayName;
import '../../../features/dashboard/student/services/student_dashboard_service.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/common/form_value_row.dart';
import '../../../core/workspace/user_list_identity_lead.dart';

/// Student dashboard team panel — form layout aligned with [StudentDashboard] My Details.
class StudentTeamOverviewCard extends StatelessWidget {
  const StudentTeamOverviewCard({
    super.key,
    required this.vm,
    this.compact = false,
  });

  final StudentDashboardVm vm;
  final bool compact;

  static const double _labelWidth = 96;
  static const double _labelGap = EntityCardStyles.labelGap;
  static const double _studentLabelTopInset = 7;
  static const Alignment _labelAlignment = Alignment.centerLeft;

  double get _rowGap => compact ? 8 : 8;

  @override
  Widget build(BuildContext context) {
    final String teamName = vm.team.teamName.trim().isEmpty ? 'No Team' : vm.team.teamName.trim();
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
              DashboardCardTitle(title: 'My Team — $teamName', icon: AppIcons.teams),
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
        FormValueRow(
          labelWidth: _labelWidth,
          labelGap: _labelGap,
          label: 'Mentor',
          labelIcon: AppIcons.faculty,
          labelAlignment: _labelAlignment,
          child: _mentorLead(),
        ),
        SizedBox(height: _rowGap),
        FormValueRow(
          labelWidth: _labelWidth,
          labelGap: _labelGap,
          label: 'Leader',
          labelIcon: AppIcons.student,
          labelAlignment: _labelAlignment,
          child: _leaderLead(),
        ),
        SizedBox(height: _rowGap),
        FormValueRow(
          labelWidth: _labelWidth,
          labelGap: _labelGap,
          label: 'Team Members',
          labelIcon: AppIcons.student,
          labelAlignment: _labelAlignment,
          crossAxisAlignment: CrossAxisAlignment.start,
          labelTopInset: _studentLabelTopInset,
          child: _studentsLead(context, members),
        ),
        SizedBox(height: _rowGap),
        _buildMetricsRows(),
      ],
    );
  }

  Widget _mentorLead() {
    final UserModel? mentor = vm.mentorUser;
    final String name = vm.mentorName.trim().isEmpty ? '—' : vm.mentorName.trim();
    if (mentor == null || mentor.userId.trim().isEmpty) {
      return EntityCardPills.plainValue(name);
    }
    return UserListIdentityLead(
      user: mentor,
      avatarRadius: 12,
    );
  }

  Widget _leaderLead() {
    final UserModel? leader = vm.teamLeaderUser;
    final String name = vm.teamLeaderName.trim().isEmpty || vm.teamLeaderName.trim() == '-'
        ? '—'
        : vm.teamLeaderName.trim();
    if (leader == null || leader.userId.trim().isEmpty) {
      return EntityCardPills.plainValue(name);
    }
    return UserListIdentityLead(
      user: leader,
      avatarRadius: 12,
    );
  }

  Widget _studentsLead(BuildContext context, List<UserModel> members) {
    if (members.isEmpty) {
      return const Text('No team members on team', style: EntityCardStyles.plainValue);
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < members.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 6),
            UserListIdentityLead(user: members[i], avatarRadius: 12),
          ],
        ],
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < members.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 6));
      rows.add(
        Row(
          children: <Widget>[
            Expanded(child: UserListIdentityLead(user: members[i], avatarRadius: 12)),
            if (i + 1 < members.length) ...<Widget>[
              const SizedBox(width: 8),
              Expanded(child: UserListIdentityLead(user: members[i + 1], avatarRadius: 12)),
            ] else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildMetricsRows() {
    final TeamStatus status = vm.team.status;
    final Color statusColor = switch (status) {
      TeamStatus.active => const Color(0xFF177C50),
      TeamStatus.inactive => const Color(0xFFB93838),
      TeamStatus.locked => const Color(0xFFB56A11),
    };
    final int ideaCount = vm.ideaCards.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FormValueRow(
          labelWidth: _labelWidth,
          labelGap: _labelGap,
          label: 'Ideas',
          labelIcon: AppIcons.ideas,
          labelAlignment: _labelAlignment,
          child: EntityCardPills.plainValue('$ideaCount idea${ideaCount == 1 ? '' : 's'}'),
        ),
        SizedBox(height: _rowGap),
        FormValueRow(
          labelWidth: _labelWidth,
          labelGap: _labelGap,
          label: 'Status',
          labelIcon: AppIcons.statusActive,
          labelAlignment: _labelAlignment,
          child: Text(
            status.value,
            style: EntityCardStyles.plainValue.copyWith(color: statusColor),
          ),
        ),
        SizedBox(height: _rowGap),
        FormValueRow(
          labelWidth: _labelWidth,
          labelGap: _labelGap,
          label: 'Created',
          labelIcon: AppIcons.clock,
          labelAlignment: _labelAlignment,
          child: EntityCardPills.plainValue(formatDateTime(vm.team.createdAt)),
        ),
      ],
    );
  }
}
