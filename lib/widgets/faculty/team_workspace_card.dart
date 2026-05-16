import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/team_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/faculty_teams_service.dart';
import '../common/card_overflow_menu.dart';
import 'student_member_chips.dart';
import 'team_idea_summary_widget.dart';

class TeamWorkspaceCard extends StatelessWidget {
  const TeamWorkspaceCard({
    super.key,
    required this.team,
    required this.insight,
    required this.mentorName,
    required this.studentNamesById,
    required this.onEdit,
    required this.onSubmitIdea,
    required this.onViewIdeas,
    required this.onDisable,
  });

  final TeamModel team;
  final FacultyTeamInsight insight;
  final String mentorName;
  final Map<String, String> studentNamesById;
  final VoidCallback onEdit;
  final VoidCallback onSubmitIdea;
  final VoidCallback onViewIdeas;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final sortedStudentIds = sortUserIdsByDisplayName(team.studentIds, studentNamesById);
    final studentNames = sortedStudentIds.map((id) => studentNamesById[id] ?? id).toList(growable: false);
    final isInactive = team.status.name == 'inactive';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(team.teamName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(AppIcons.clock, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Created ${formatDateTime(team.createdAt)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              CardOverflowMenuButton(
                tooltip: 'Team actions',
                dividersBefore: const <String>{'disable'},
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'submit':
                      onSubmitIdea();
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
                  CardOverflowMenuAction(
                    value: 'submit',
                    icon: AppIcons.ideas,
                    label: 'Submit Idea',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _metaChip(AppIcons.student, '${team.studentIds.length} students'),
              _metaChip(AppIcons.faculty, mentorName.isEmpty ? 'Mentor assigned' : mentorName),
            ],
          ),
          const SizedBox(height: 8),
          StudentMemberChips(names: studentNames),
          const SizedBox(height: 10),
          TeamIdeaSummaryWidget(insight: insight),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
