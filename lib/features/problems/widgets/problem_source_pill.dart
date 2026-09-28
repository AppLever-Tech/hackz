import 'package:flutter/material.dart';

import '../services/problem_status_helpers.dart';

class ProblemSourcePill extends StatelessWidget {
  const ProblemSourcePill({
    super.key,
    required this.createdSource,
    this.compact = true,
  });

  final String? createdSource;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = ProblemStatusHelpers.sourceColor(createdSource);
    final Color bg = ProblemStatusHelpers.sourceBackground(createdSource);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(ProblemStatusHelpers.sourceIcon(createdSource), size: compact ? 11 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            ProblemStatusHelpers.sourceLabel(createdSource),
            style: TextStyle(
              fontSize: compact ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
