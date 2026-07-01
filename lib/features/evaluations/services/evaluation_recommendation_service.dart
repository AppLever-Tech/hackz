import '../models/evaluation_recommendation_level.dart';

/// Advisory recommendation engine for department-admin shortlisting review.
abstract final class EvaluationRecommendationService {
  EvaluationRecommendationService._();

  static const double _recommendedBandPercent = 15;

  static EvaluationRecommendationLevel? compute({
    required bool enabled,
    required double? averageScore,
    required int scoringScale,
    required double thresholdPercent,
  }) {
    if (!enabled || averageScore == null || scoringScale <= 0) return null;
    final double percent = (averageScore / scoringScale) * 100;
    if (percent >= thresholdPercent) {
      return EvaluationRecommendationLevel.highlyRecommended;
    }
    if (percent >= thresholdPercent - _recommendedBandPercent) {
      return EvaluationRecommendationLevel.recommended;
    }
    return EvaluationRecommendationLevel.needsReview;
  }
}
