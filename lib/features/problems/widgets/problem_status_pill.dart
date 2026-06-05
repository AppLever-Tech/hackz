import 'package:flutter/material.dart';

import '../models/problem_status.dart';
import '../services/problem_status_helpers.dart';

class ProblemStatusPill extends StatelessWidget {
  const ProblemStatusPill({
    super.key,
    required this.status,
    this.compact = true,
  });

  final ProblemStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = ProblemStatusHelpers.color(status);
    final Color bg = ProblemStatusHelpers.background(status);
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
          Icon(ProblemStatusHelpers.icon(status), size: compact ? 11 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            ProblemStatusHelpers.label(status),
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
