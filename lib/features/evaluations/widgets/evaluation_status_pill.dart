import 'package:flutter/material.dart';

import '../../../constants/status_styles.dart';
import '../../idea/services/idea_status_helpers.dart';
import 'package:hackz/features/idea/models/idea_model.dart';

class EvaluationStatusPill extends StatelessWidget {
  const EvaluationStatusPill({super.key, required this.status, this.compact = false});

  final IdeaStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = StatusStyles.colorForIdeaStatus(status);
    final String label = IdeaStatusHelpers.label(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
