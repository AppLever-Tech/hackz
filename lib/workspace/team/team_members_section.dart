import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import 'team_workspace.dart';
import 'team_workspace_loader.dart';

class TeamMembersSection extends StatelessWidget {
  const TeamMembersSection({super.key, required this.vm});

  final TeamWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.members.isEmpty) {
      return const _SectionShell(
        child: Text(
          'No members linked to this team yet.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        ),
      );
    }

    TeamMemberPreview? mentor;
    for (final TeamMemberPreview m in vm.members) {
      if (m.isMentor) {
        mentor = m;
        break;
      }
    }
    final List<TeamMemberPreview> students =
        vm.members.where((TeamMemberPreview m) => !m.isMentor).toList(growable: false);

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (mentor != null) ...<Widget>[
            const Text('Mentor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            _mentorSummary(context, mentor),
            const SizedBox(height: 12),
          ],
          const Text('Students', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          if (students.isEmpty)
            const Text('No students assigned.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: students
                    .map((TeamMemberPreview m) => _studentCard(context, m))
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mentorSummary(BuildContext context, TeamMemberPreview mentor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFEAF2FF),
            child: Icon(AppIcons.faculty, size: 16, color: Color(0xFF4A67FF)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  onTap: mentor.userId.trim().isEmpty
                      ? null
                      : () => TeamWorkspace.openUserFromTeam(context, mentor.userId),
                  child: Text(
                    mentor.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(height: 4),
                _roleChip(mentor.roleLabel, const Color(0xFF6A38FF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard(BuildContext context, TeamMemberPreview member) {
    final String initial = member.displayName.trim().isEmpty
        ? '?'
        : member.displayName.trim().substring(0, 1).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFFDCE6FF),
            child: Text(initial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                onTap: member.userId.trim().isEmpty
                    ? null
                    : () => TeamWorkspace.openUserFromTeam(context, member.userId),
                child: Text(
                  member.displayName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ),
              const SizedBox(height: 4),
              _roleChip(member.roleLabel, const Color(0xFF4A67FF)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _roleChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Members',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
