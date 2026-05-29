import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';

class TeamCapacityWidget extends StatelessWidget {
  const TeamCapacityWidget({
    super.key,
    required this.teamCount,
    required this.maxTeams,
  });

  final int teamCount;
  final int maxTeams;

  @override
  Widget build(BuildContext context) {
    final remaining = (maxTeams - teamCount).clamp(0, maxTeams).toInt();
    final reached = remaining == 0;
    final color = reached ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(reached ? AppIcons.verification : AppIcons.teams, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              reached ? 'Team capacity reached' : (remaining == 1 ? '1 team slot remaining' : '$remaining team slots remaining'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
