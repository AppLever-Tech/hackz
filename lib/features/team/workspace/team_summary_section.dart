import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/enums/team_status.dart';
import '../../../utils/common_helpers.dart';
import 'team_workspace_loader.dart';

class TeamSummarySection extends StatelessWidget {
  const TeamSummarySection({super.key, required this.vm});

  final TeamWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final team = vm.team;
    final String name = team.teamName.trim().isEmpty ? 'Innovation team' : team.teamName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(AppIcons.teams, size: 22, color: Color(0xFF4A67FF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _chip(AppIcons.faculty, 'Mentor', vm.mentorName),
                      _chip(AppIcons.departments, 'Department', vm.departmentLabel),
                      _chip(AppIcons.clock, 'Created', formatDateTime(team.createdAt)),
                      _statusChip(team.status),
                      _chip(AppIcons.student, 'Members', '${vm.memberCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _chip(IconData icon, String label, String value) {
    final String text = value.trim().isEmpty ? '—' : value.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF57629A)),
          const SizedBox(width: 6),
          Text(
            '$label: $text',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip(TeamStatus status) {
    final Color color = switch (status) {
      TeamStatus.active => const Color(0xFF177C50),
      TeamStatus.inactive => const Color(0xFFB93838),
      TeamStatus.locked => const Color(0xFFB56A11),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            status == TeamStatus.active ? AppIcons.statusActive : AppIcons.statusInactive,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            teamStatusLabel(status),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
