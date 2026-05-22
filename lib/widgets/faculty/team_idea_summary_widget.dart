import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/team_status.dart';
import '../../utils/common_helpers.dart';
import '../../utils/faculty_teams_service.dart';

class TeamIdeaSummaryWidget extends StatelessWidget {
  const TeamIdeaSummaryWidget({
    super.key,
    required this.insight,
  });

  final FacultyTeamInsight insight;

  @override
  Widget build(BuildContext context) {
    final TeamStatus status = insight.team.status;
    final Color statusColor = switch (status) {
      TeamStatus.active => const Color(0xFF177C50),
      TeamStatus.inactive => const Color(0xFFB93838),
      TeamStatus.locked => const Color(0xFFB56A11),
    };

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _infoLine(AppIcons.ideas, '${insight.ideas.length} idea${insight.ideas.length == 1 ? '' : 's'}'),
        _infoLine(AppIcons.statusActive, 'Team status: ${status.value}', color: statusColor),
        _infoLine(AppIcons.clock, 'Created ${formatDateTime(insight.team.createdAt)}'),
      ],
    );
  }

  Widget _infoLine(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color ?? const Color(0xFF64748B)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
