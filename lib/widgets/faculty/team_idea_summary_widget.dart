import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../utils/faculty_teams_service.dart';

class TeamIdeaSummaryWidget extends StatelessWidget {
  const TeamIdeaSummaryWidget({
    super.key,
    required this.insight,
  });

  final FacultyTeamInsight insight;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _chip(AppIcons.ideas, '${insight.ideas.length} ideas', const Color(0xFF6A38FF)),
        if (!insight.hasIdeas) _chip(AppIcons.statusSubmitted, 'Pending submission', const Color(0xFF64748B)),
        _chip(AppIcons.payments, insight.hasPendingPayment ? 'Payment pending' : 'Payment clear', insight.hasPendingPayment ? const Color(0xFFEA580C) : const Color(0xFF16A34A)),
        _chip(AppIcons.scoring, insight.hasEvaluation ? 'Evaluated' : 'Awaiting evaluation', insight.hasEvaluation ? const Color(0xFF0891B2) : const Color(0xFF64748B)),
        _chip(AppIcons.verification, insight.isLocked ? 'Locked' : 'Unlocked', insight.isLocked ? const Color(0xFF7C3AED) : const Color(0xFF16A34A)),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
