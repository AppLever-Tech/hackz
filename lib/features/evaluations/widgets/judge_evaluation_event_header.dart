import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';

/// Compact Ideathon/event header used to group a judge's assigned ideas.
class JudgeEvaluationEventHeader extends StatelessWidget {
  const JudgeEvaluationEventHeader({
    super.key,
    required this.name,
    this.schedule = '',
  });

  final String name;
  final String schedule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.ideathons, size: 16, color: Color(0xFF6A38FF)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          if (schedule.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              schedule.trim(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }
}
