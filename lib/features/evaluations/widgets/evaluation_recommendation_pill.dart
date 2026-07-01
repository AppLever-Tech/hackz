import 'package:flutter/material.dart';

import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../models/evaluation_recommendation_level.dart';

/// Semantic pill for advisory shortlisting recommendations.
class EvaluationRecommendationPill extends StatelessWidget {
  const EvaluationRecommendationPill({
    super.key,
    required this.level,
  });

  final EvaluationRecommendationLevel level;

  @override
  Widget build(BuildContext context) {
    return ProblemWorkflowActionPill(
      label: EvaluationRecommendationLevelHelpers.label(level),
      semantic: EvaluationRecommendationLevelHelpers.semantic(level),
      tooltip: 'Advisory recommendation only',
    );
  }
}
