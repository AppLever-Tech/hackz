import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/team_model.dart';
import '../../../utils/common_helpers.dart';
import '../services/faculty_teams_service.dart';
import '../../../workspace/workspace.dart';
import '../../../widgets/common/card_overflow_menu.dart';
import 'team_idea_summary_widget.dart';

class TeamWorkspaceCard extends StatelessWidget {
  const TeamWorkspaceCard({
    super.key,
    required this.team,
    required this.insight,
    required this.mentorName,
    required this.studentNamesById,
    required this.onEdit,
    required this.onViewIdeas,
    required this.onDisable,
  });

  final TeamModel team;
  final FacultyTeamInsight insight;
  final String mentorName;
  final Map<String, String> studentNamesById;
  final VoidCallback onEdit;
  final VoidCallback onViewIdeas;
  final VoidCallback onDisable;

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
              Expanded(child: _buildTeamTitleRow(context)),
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
          _buildFacultyRow(context),
          const SizedBox(height: 8),
          _buildStudentsRow(context, sortedStudentIds),
          const SizedBox(height: 8),
          TeamIdeaSummaryWidget(insight: insight),
        ],
      ),
    );
  }

  Widget _buildTeamTitleRow(BuildContext context) {
    final String teamId = team.teamId.trim();
    if (teamId.isNotEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: ContextPill(
          label: team.teamName,
          semantic: ContextPillSemantic.team,
          onTap: () => WorkspaceNavigator.openTeam(context, teamId),
          compact: true,
        ),
      );
    }

    return Text(
      team.teamName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildFacultyRow(BuildContext context) {
    final String mentorId = team.mentorId.trim();
    if (mentorId.isNotEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _userPill(
          context,
          userId: mentorId,
          label: mentorName.trim().isEmpty ? 'Faculty mentor' : mentorName.trim(),
          icon: AppIcons.faculty,
        ),
      );
    }
    if (mentorName.trim().isNotEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _plainMemberLabel(mentorName.trim(), AppIcons.faculty),
      );
    }
    return const Text('No faculty assigned', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)));
  }

  Widget _buildStudentsRow(BuildContext context, List<String> sortedStudentIds) {
    final List<Widget> pills = <Widget>[];
    for (final String studentId in sortedStudentIds) {
      final String name = (studentNamesById[studentId] ?? studentId).trim();
      if (studentId.isEmpty) continue;
      pills.add(
        _userPill(
          context,
          userId: studentId,
          label: name.isEmpty ? studentId : name,
          icon: AppIcons.student,
        ),
      );
    }

    if (pills.isEmpty) {
      return const Text('No students assigned', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pills,
    );
  }

  Widget _userPill(
    BuildContext context, {
    required String userId,
    required String label,
    required IconData icon,
  }) {
    return ContextPill(
      label: label,
      semantic: ContextPillSemantic.user,
      icon: icon,
      onTap: () => WorkspaceNavigator.openUser(context, userId),
      compact: true,
    );
  }

  Widget _plainMemberLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      ],
    );
  }
}
