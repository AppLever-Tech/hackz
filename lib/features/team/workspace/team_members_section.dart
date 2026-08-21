import 'package:flutter/material.dart';

import '../../../core/workspace/user_workspace_avatar.dart';
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
            const Text(
              'Mentor',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            _memberRow(context, mentor),
            const SizedBox(height: 12),
          ],
          const Text(
            'Team Members',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          if (students.isEmpty)
            const Text('No team members assigned.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
          else
            Column(
              children: students
                  .map((TeamMemberPreview m) => _memberRow(context, m))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _memberRow(BuildContext context, TeamMemberPreview member) {
    final String userId = member.userId.trim();
    final bool canOpenUser = userId.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (member.user != null && canOpenUser)
            UserWorkspaceAvatar(
              user: member.user!,
              radius: 12,
              ringPadding: 2,
              onTap: () => TeamWorkspace.openUserFromTeam(context, userId),
            )
          else
            _fallbackAvatar(member.displayName),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              member.displayName.trim().isEmpty ? '—' : member.displayName.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fallbackAvatar(String displayName) {
    final String trimmed = displayName.trim();
    final String initial = trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFEEF2FF),
      foregroundColor: const Color(0xFF4F46E5),
      child: Text(initial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
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
