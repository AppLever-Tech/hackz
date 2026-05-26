import '../models/idea_model.dart';
import '../models/payment_model.dart';
import '../features/problems/models/problem_model.dart';

/// Extensible weighted ranking for innovation leaderboard showcase.
/// Default: 70% evaluation, 20% innovation/completeness, 10% submission & payment completeness.
class LeaderboardRankingWeights {
  const LeaderboardRankingWeights({
    this.evaluationShare = 0.70,
    this.innovationShare = 0.20,
    this.submissionCompletenessShare = 0.10,
  });

  final double evaluationShare;
  final double innovationShare;
  final double submissionCompletenessShare;

  static const LeaderboardRankingWeights standard = LeaderboardRankingWeights();
}

class LeaderboardRankingEngine {
  const LeaderboardRankingEngine({this.weights = LeaderboardRankingWeights.standard});

  final LeaderboardRankingWeights weights;

  /// Normalizes raw judge scores (typically 0–10) to 0–100.
  double normalizedEvaluation(double avgJudgeScore, {double maxScale = 10}) {
    if (maxScale <= 0) return 0;
    return ((avgJudgeScore / maxScale * 100).clamp(0, 100)).toDouble();
  }

  /// Proxy for innovation / solution completeness from idea + problem metadata (0–1).
  double innovationFactor(IdeaModel idea, ProblemModel? problem) {
    final descScore = (idea.description.length / 600).clamp(0.0, 1.0);
    final filesScore = (idea.files.length / 6).clamp(0.0, 1.0);
    double meta = 0.0;
    if (problem != null) {
      if (problem.theme.trim().isNotEmpty) meta += 0.35;
      if (problem.category.trim().isNotEmpty) meta += 0.35;
      if (problem.tags.isNotEmpty) meta += 0.30;
    }
    return ((descScore + filesScore * 0.8 + meta) / 2.2).clamp(0.0, 1.0);
  }

  /// Submission + payment pathway completeness (0–1).
  double submissionPaymentCompleteness(IdeaModel idea, PaymentModel? payment) {
    final double submission = switch (idea.status) {
      IdeaStatus.pendingSubmission => 0.35,
      IdeaStatus.submitted => 0.72,
      IdeaStatus.underReview => 0.82,
      IdeaStatus.evaluated => 0.92,
      IdeaStatus.approved => 1.0,
      IdeaStatus.rejected => 1.0,
    };
    double pay = 0.65;
    if (payment != null) {
      pay = switch (payment.status) {
        PaymentRecordStatus.verified => 1.0,
        PaymentRecordStatus.pending => 0.55,
        PaymentRecordStatus.rejected => 0.40,
      };
    }
    return (submission * 0.55 + pay * 0.45).clamp(0.0, 1.0);
  }

  /// Composite score 0–100.
  double compositeIdeaScore({
    required double avgJudgeScore,
    required IdeaModel idea,
    required ProblemModel? problem,
    PaymentModel? payment,
    double judgeScoreMax = 10,
  }) {
    final evalNorm = normalizedEvaluation(avgJudgeScore, maxScale: judgeScoreMax);
    final innov = innovationFactor(idea, problem) * 100;
    final sub = submissionPaymentCompleteness(idea, payment) * 100;
    return evalNorm * weights.evaluationShare +
        innov * weights.innovationShare +
        sub * weights.submissionCompletenessShare;
  }
}

enum TrendDirection { up, down, stable }

TrendDirection trendFromDelta(double delta, {double epsilon = 0.08}) {
  if (delta > epsilon) return TrendDirection.up;
  if (delta < -epsilon) return TrendDirection.down;
  return TrendDirection.stable;
}
