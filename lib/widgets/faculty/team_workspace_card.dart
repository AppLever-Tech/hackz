import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/team_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/faculty_teams_service.dart';
import '../../workspace/workspace.dart';
import '../common/card_overflow_menu.dart';
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
              Expanded(
                child: team.teamId.trim().isNotEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: ContextPill(
                          label: team.teamName,
                          semantic: ContextPillSemantic.team,
                          onTap: () => WorkspaceNavigator.openTeam(context, team.teamId),
                        ),
                      )
                    : Text(
                        team.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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
                    icon: AppIcons.edit,
                    label: 'Edit Team',
                    enabled: !insight.isLocked && !isInactive,
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
          const SizedBox(height: 10),
          _memberPills(context, sortedStudentIds),
          const SizedBox(height: 10),
          TeamIdeaSummaryWidget(insight: insight),
        ],
      ),
    );
  }

  Widget _memberPills(BuildContext context, List<String> sortedStudentIds) {
    final List<Widget> pills = <Widget>[];

    final String mentorId = team.mentorId.trim();
    if (mentorId.isNotEmpty) {
      pills.add(
        _userPill(
          context,
          userId: mentorId,
          label: mentorName.trim().isEmpty ? 'Faculty mentor' : mentorName.trim(),
          icon: AppIcons.faculty,
        ),
      );
    } else if (mentorName.trim().isNotEmpty) {
      pills.add(_plainMemberLabel(mentorName.trim(), AppIcons.faculty));
    }

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
      return const Text('No members assigned', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)));
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
