import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../screens/common/dashboard_components.dart';
import '../models/evaluation_details_view_model.dart';

/// Compact per-judge score distribution to surface scoring disagreements.
class EvaluationScoreDistribution extends StatelessWidget {
  const EvaluationScoreDistribution({
    super.key,
    required this.judgeDetails,
    required this.scoringScale,
  });

  final List<EvaluationJudgeDetail> judgeDetails;
  final int scoringScale;

  @override
  Widget build(BuildContext context) {
    if (judgeDetails.isEmpty) return const SizedBox.shrink();

    final List<EvaluationJudgeDetail> sorted = List<EvaluationJudgeDetail>.from(judgeDetails)
      ..sort((EvaluationJudgeDetail a, EvaluationJudgeDetail b) =>
          b.entry.overallScore.compareTo(a.entry.overallScore));

    final double maxScore = sorted
        .map((EvaluationJudgeDetail d) => d.entry.overallScore)
        .reduce((double a, double b) => a > b ? a : b);
    final double minScore = sorted
        .map((EvaluationJudgeDetail d) => d.entry.overallScore)
        .reduce((double a, double b) => a < b ? a : b);
    final int scale = scoringScale;
    final double safeMax = scale <= 0 ? 1 : scale.toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(AppIcons.insights, size: 18, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                'Score Distribution',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Compare judge scores to spot unusually high or low evaluations.',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final EvaluationJudgeDetail detail in sorted)
            _JudgeScoreRow(
              judgeName: detail.entry.judgeName,
              score: detail.entry.overallScore,
              scale: scale,
              safeMax: safeMax,
              highlight: detail.entry.overallScore == maxScore || detail.entry.overallScore == minScore,
            ),
        ],
      ),
    );
  }
}

class _JudgeScoreRow extends StatelessWidget {
  const _JudgeScoreRow({
    required this.judgeName,
    required this.score,
    required this.scale,
    required this.safeMax,
    required this.highlight,
  });

  final String judgeName;
  final double score;
  final int scale;
  final double safeMax;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final double pct = (score / safeMax).clamp(0.0, 1.0);
    final Color accent = highlight
        ? (score >= safeMax * 0.85 ? const Color(0xFF059669) : const Color(0xFFDC2626))
        : const Color(0xFF6366F1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  judgeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
              ),
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: const Color(0xFFE2E8F0),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
