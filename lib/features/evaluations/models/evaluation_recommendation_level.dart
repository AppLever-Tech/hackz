import '../../../features/problems/widgets/problem_workflow_action_pill.dart';

/// Advisory shortlisting recommendation — never triggers automatic shortlisting.
enum EvaluationRecommendationLevel {
  highlyRecommended,
  recommended,
  needsReview,
}

abstract final class EvaluationRecommendationLevelHelpers {
  EvaluationRecommendationLevelHelpers._();

  static String label(EvaluationRecommendationLevel level) {
    return switch (level) {
      EvaluationRecommendationLevel.highlyRecommended => 'Highly Recommended',
      EvaluationRecommendationLevel.recommended => 'Recommended',
      EvaluationRecommendationLevel.needsReview => 'Needs Review',
    };
  }

  static ProblemWorkflowPillSemantic semantic(EvaluationRecommendationLevel level) {
    return switch (level) {
      EvaluationRecommendationLevel.highlyRecommended => ProblemWorkflowPillSemantic.primary,
      EvaluationRecommendationLevel.recommended => ProblemWorkflowPillSemantic.pending,
      EvaluationRecommendationLevel.needsReview => ProblemWorkflowPillSemantic.closed,
    };
  }
}
