import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../user/models/enums/user_status.dart';
import '../../user/models/user_model.dart';
import '../models/team_model.dart';
import '../../../utils/common_helpers.dart';
import '../services/faculty_teams_service.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/workspace/user_list_identity_lead.dart';
import '../../../core/ui/common/card_overflow_menu.dart';
import '../../../core/ui/common/form_value_row.dart';
import 'team_idea_summary_widget.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

class TeamWorkspaceCard extends StatelessWidget {
  const TeamWorkspaceCard({
    super.key,
    required this.team,
    required this.insight,
    required this.mentorUser,
    required this.studentsById,
    required this.studentNamesById,
    required this.onEdit,
    required this.onViewIdeas,
    required this.onDisable,
  });

  final TeamModel team;
  final FacultyTeamInsight insight;
  final UserModel mentorUser;
  final Map<String, UserModel> studentsById;
  final Map<String, String> studentNamesById;
  final VoidCallback onEdit;
  final VoidCallback onViewIdeas;
  final VoidCallback onDisable;

  static const double _labelWidth = 52;
  static const double _labelGap = 4;
  static const double _studentLabelTopInset = 7;
  static const Alignment _labelAlignment = Alignment.centerLeft;

  @override
  Widget build(BuildContext context) {
    final List<String> sortedStudentIds = sortUserIdsByDisplayName(team.studentIds, studentNamesById);
    final bool isInactive = team.status.name == 'inactive';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x120F172A), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
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
                dividersBefore: const <String>{'disable'},
                onSelected: (String value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'view':
                      onViewIdeas();
                    case 'disable':
                      onDisable();
                  }
                },
                actions: <CardOverflowMenuAction>[
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
            label: 'Mentor',
            labelAlignment: _labelAlignment,
            child: _buildMentorValue(context),
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
          FormValueRow(
            labelWidth: _labelWidth,
            labelGap: _labelGap,
            label: 'Team Members',
            labelAlignment: _labelAlignment,
            crossAxisAlignment: CrossAxisAlignment.start,
            labelTopInset: _studentLabelTopInset,
            child: _buildStudentsValue(context, sortedStudentIds),
          ),
          const SizedBox(height: 8),
          TeamIdeaSummaryWidget(insight: insight),
        ],
      ),
    );
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

  Widget _buildMentorValue(BuildContext context) {
    final UserModel mentor = _resolveMentor();
    return UserListIdentityLead(
      user: mentor,
      avatarRadius: 12,
    );
  }

  Widget _buildStudentsValue(BuildContext context, List<String> sortedStudentIds) {
    if (sortedStudentIds.isEmpty) {
      return const Text('No team members assigned', style: EntityCardStyles.plainValue);
    }

    final bool mobile = ResponsiveHelper.isMobile(context);
    final List<UserModel> students = sortedStudentIds
        .map((String id) => _resolveStudent(id))
        .toList(growable: false);

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < students.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 6),
            UserListIdentityLead(
              user: students[i],
              avatarRadius: 12,
            ),
          ],
        ],
      );
    }

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < students.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 6));
      rows.add(
        Row(
          children: <Widget>[
            Expanded(
              child: UserListIdentityLead(
                user: students[i],
                avatarRadius: 12,
              ),
            ),
            if (i + 1 < students.length) ...<Widget>[
              const SizedBox(width: 8),
              Expanded(
                child: UserListIdentityLead(
                  user: students[i + 1],
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
      user: _resolveStudent(leaderId),
      avatarRadius: 12,
    );
  }

  UserModel _resolveMentor() {
    final String mentorId = team.mentorId.trim();
    if (mentorId.isEmpty) {
      return _stubUser('', '—', role: 'FAC');
    }
    if (mentorUser.userId == mentorId) {
      return mentorUser;
    }
    return studentsById[mentorId] ?? _stubUser(mentorId, mentorUser.displayName, role: 'FAC');
  }

  UserModel _resolveStudent(String studentId) {
    return studentsById[studentId] ??
        _stubUser(
          studentId,
          (studentNamesById[studentId] ?? studentId).trim(),
          role: 'STU',
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
