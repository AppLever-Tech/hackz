import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';

/// Non-blocking warning banner surfaced when a workflow change could impact
/// downstream artifacts (e.g. team change on an already-evaluated idea).
class WorkflowEvaluationWarning extends StatelessWidget {
  const WorkflowEvaluationWarning({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  /// Convenience builder for the most common team-evaluation case.
  factory WorkflowEvaluationWarning.teamEvaluated() {
    return const WorkflowEvaluationWarning(
      title: 'Team has already been evaluated',
      message:
          'Membership changes may affect evaluation integrity. Please coordinate with judges before submitting.',
      icon: AppIcons.workflowPendingReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE4B0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: const Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7C2D12),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8B4513),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
