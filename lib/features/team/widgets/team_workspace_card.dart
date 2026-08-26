import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/enums/user_status.dart';
import '../../user/models/user_model.dart';
import '../models/team_model.dart';
import '../models/enums/team_status.dart';
import '../../../utils/common_helpers.dart';
import '../services/teams_workspace_service.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/workspace/user_list_identity_lead.dart';
import '../../../core/ui/common/card_overflow_menu.dart';
import '../../../core/ui/common/form_value_row.dart';
import 'team_idea_summary_widget.dart';
import 'team_status_pill.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

class TeamWorkspaceCard extends StatelessWidget {
  const TeamWorkspaceCard({
    super.key,
    required this.team,
    required this.insight,
    required this.membersById,
    required this.memberNamesById,
    required this.onEdit,
    required this.onViewIdeas,
    required this.onDisable,
    this.compact = false,
    this.onOpen,
  });

  final TeamModel team;
  final TeamWorkspaceInsight insight;
  final Map<String, UserModel> membersById;
  final Map<String, String> memberNamesById;
  final VoidCallback onEdit;
  final VoidCallback onViewIdeas;
  final VoidCallback onDisable;
  final bool compact;
  final VoidCallback? onOpen;

  static const double _labelWidth = 52;
  static const double _labelGap = 4;
  static const double _memberLabelTopInset = 7;
  static const Alignment _labelAlignment = Alignment.centerLeft;

  @override
  Widget build(BuildContext context) {
    final List<String> sortedMemberIds = sortUserIdsByDisplayName(team.studentIds, memberNamesById);
    final bool isInactive = team.status.name == 'inactive';
    final VoidCallback? openTeam = onOpen ??
        (team.teamId.trim().isEmpty ? null : () => WorkspaceNavigator.openTeam(context, team.teamId.trim()));

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: FormValueRow(
                labelWidth: _labelWidth,
                labelGap: _labelGap,
                label: 'Team',
                labelAlignment: _labelAlignment,
                child: _buildTeamValue(context),
              ),
            ),
            const SizedBox(width: 6),
            CardOverflowMenuButton(
              tooltip: 'Team actions',
              dividersBefore: compact ? const <String>{} : const <String>{'disable'},
              onSelected: (String value) {
                switch (value) {
                  case 'open':
                    openTeam?.call();
                  case 'edit':
                    onEdit();
                  case 'view':
                    onViewIdeas();
                  case 'disable':
                    onDisable();
                }
              },
              actions: compact
                  ? <CardOverflowMenuAction>[
                      CardOverflowMenuAction(
                        value: 'open',
                        icon: AppIcons.openInNew,
                        label: 'Open team',
                        enabled: openTeam != null,
                      ),
                    ]
                  : <CardOverflowMenuAction>[
                      CardOverflowMenuAction(
                        value: 'edit',
                        icon: Icons.published_with_changes_rounded,
                        label: 'Request Team Change',
                        enabled: !isInactive,
                      ),
                      const CardOverflowMenuAction(
                        value: 'view',
                        icon: AppIcons.preview,
                        label: 'View Ideas',
                      ),
                      CardOverflowMenuAction(
                        value: 'disable',
                        icon: AppIcons.statusInactive,
                        label: 'Disable Team',
                        enabled: !isInactive,
                        danger: true,
                      ),
                    ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        FormValueRow(
          labelWidth: _labelWidth,
          labelGap: _labelGap,
          label: 'Leader',
          labelAlignment: _labelAlignment,
          child: _buildLeaderValue(context),
        ),
        const SizedBox(height: 8),
        if (compact)
          FormValueRow(
            labelWidth: _labelWidth,
            labelGap: _labelGap,
            label: 'Members',
            labelAlignment: _labelAlignment,
            child: Text(
              '${sortedMemberIds.length} member${sortedMemberIds.length == 1 ? '' : 's'}',
              style: EntityCardStyles.plainValue,
            ),
          )
        else
          FormValueRow(
            labelWidth: _labelWidth,
            labelGap: _labelGap,
            label: 'Team Members',
            labelAlignment: _labelAlignment,
            crossAxisAlignment: CrossAxisAlignment.start,
            labelTopInset: _memberLabelTopInset,
            child: _buildMembersValue(context, sortedMemberIds),
          ),
        const SizedBox(height: 8),
        if (compact)
          FormValueRow(
            labelWidth: _labelWidth,
            labelGap: _labelGap,
            label: 'Status',
            labelAlignment: _labelAlignment,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                TeamStatusPill(
                  status: team.status,
                  lockedAfterSubmission: insight.isLocked && team.status != TeamStatus.inactive,
                ),
                Text(
                  '${insight.ideas.length} idea${insight.ideas.length == 1 ? '' : 's'}',
                  style: EntityCardStyles.plainValue,
                ),
              ],
            ),
          )
        else
          TeamIdeaSummaryWidget(insight: insight),
      ],
    );

    final Widget card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x120F172A), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: compact && openTeam != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: openTeam,
                borderRadius: BorderRadius.circular(18),
                child: Padding(padding: const EdgeInsets.all(12), child: body),
              ),
            )
          : Padding(padding: const EdgeInsets.all(12), child: body),
    );

    return card;
  }

  Widget _buildTeamValue(BuildContext context) {
    final String teamId = team.teamId.trim();
    final String teamName = team.teamName.trim().isEmpty ? '—' : team.teamName.trim();

    if (teamId.isEmpty) {
      return Text(teamName, style: EntityCardStyles.plainValue);
    }

    return ContextPill(
      label: teamName,
      semantic: ContextPillSemantic.team,
      onTap: () => WorkspaceNavigator.openTeam(context, teamId),
      compact: true,
      fitContent: true,
    );
  }

  Widget _buildMembersValue(BuildContext context, List<String> sortedMemberIds) {
    if (sortedMemberIds.isEmpty) {
      return const Text('No team members assigned', style: EntityCardStyles.plainValue);
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    final List<UserModel> members = sortedMemberIds
        .map((String id) => _resolveMember(id))
        .toList(growable: false);

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < members.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 6),
            UserListIdentityLead(
              user: members[i],
              avatarRadius: 12,
            ),
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
            Expanded(
              child: UserListIdentityLead(
                user: members[i],
                avatarRadius: 12,
              ),
            ),
            if (i + 1 < members.length) ...<Widget>[
              const SizedBox(width: 8),
              Expanded(
                child: UserListIdentityLead(
                  user: members[i + 1],
                  avatarRadius: 12,
                ),
              ),
            ] else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildLeaderValue(BuildContext context) {
    final String leaderId = team.teamLeaderId.trim();
    if (leaderId.isEmpty) {
      return const Text('—', style: EntityCardStyles.plainValue);
    }
    return UserListIdentityLead(
      user: _resolveMember(leaderId),
      avatarRadius: 12,
    );
  }

  UserModel _resolveMember(String memberId) {
    return membersById[memberId] ??
        _stubUser(
          memberId,
          (memberNamesById[memberId] ?? memberId).trim(),
          role: UserRole.teamMember.code,
        );
  }

  UserModel _stubUser(String userId, String displayName, {required String role}) {
    final List<String> parts = displayName.trim().split(RegExp(r'\s+'));
    return UserModel(
      userId: userId,
      phone: '',
      firstName: parts.isNotEmpty ? parts.first : '',
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      email: '',
      role: role,
      orgType: null,
      orgId: team.orgId,
      department: '',
      departmentCode: team.departmentCode,
      status: UserStatus.active,
      createdAt: DateTime.now(),
    );
  }
}
