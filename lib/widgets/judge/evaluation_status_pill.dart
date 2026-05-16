import 'package:flutter/material.dart';

import '../../constants/status_styles.dart';
import '../../models/idea_model.dart';

class EvaluationStatusPill extends StatelessWidget {
  const EvaluationStatusPill({super.key, required this.status});

  final IdeaStatus status;

  @override
  Widget build(BuildContext context) {
    final color = StatusStyles.colorForIdeaStatus(status);
    final label = switch (status) {
      IdeaStatus.pendingSubmission => 'Pending payment',
      IdeaStatus.submitted => 'Submitted',
      IdeaStatus.underReview => 'Under review',
      IdeaStatus.evaluated => 'Evaluated',
      IdeaStatus.approved => 'Approved',
      IdeaStatus.rejected => 'Rejected',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
