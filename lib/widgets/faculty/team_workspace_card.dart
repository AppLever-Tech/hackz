import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/team_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/faculty_teams_service.dart';
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
              _TeamOverflowMenu(
                canEdit: !insight.isLocked && !isInactive,
                canSubmitIdea: !isInactive,
                canDisable: !isInactive,
                onEdit: onEdit,
                onSubmitIdea: onSubmitIdea,
                onViewIdeas: onViewIdeas,
                onDisable: onDisable,
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

class _TeamOverflowMenu extends StatelessWidget {
  const _TeamOverflowMenu({
    required this.canEdit,
    required this.canSubmitIdea,
    required this.canDisable,
    required this.onEdit,
    required this.onSubmitIdea,
    required this.onViewIdeas,
    required this.onDisable,
  });

  final bool canEdit;
  final bool canSubmitIdea;
  final bool canDisable;
  final VoidCallback onEdit;
  final VoidCallback onSubmitIdea;
  final VoidCallback onViewIdeas;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Team actions',
      color: Colors.white,
      elevation: 14,
      shadowColor: const Color(0x220F172A),
      surfaceTintColor: Colors.transparent,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(minWidth: 190),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.zero,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(AppIcons.more, size: 20, color: Color(0xFF475569)),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'submit':
            onSubmitIdea();
            break;
          case 'view':
            onViewIdeas();
            break;
          case 'disable':
            onDisable();
            break;
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          enabled: canEdit,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: _MenuItem(icon: AppIcons.edit, label: 'Edit Team', enabled: canEdit),
        ),
        PopupMenuItem<String>(
          value: 'submit',
          enabled: canSubmitIdea,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: _MenuItem(icon: AppIcons.ideas, label: 'Submit Idea', enabled: canSubmitIdea),
        ),
        const PopupMenuItem<String>(
          value: 'view',
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: _MenuItem(icon: AppIcons.preview, label: 'View Ideas'),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem<String>(
          value: 'disable',
          enabled: canDisable,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: _MenuItem(icon: AppIcons.statusInactive, label: 'Disable Team', enabled: canDisable, danger: true),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? const Color(0xFF94A3B8)
        : danger
            ? const Color(0xFFDC2626)
            : const Color(0xFF4F46E5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: enabled ? color.withOpacity(0.07) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: enabled ? color.withOpacity(0.11) : const Color(0xFFE2E8F0), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: danger && enabled ? color : const Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
