import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/status_styles.dart';

class IdeaStatusDistributionDonut extends StatelessWidget {
  const IdeaStatusDistributionDonut({
    super.key,
    required this.pending,
    required this.submitted,
    required this.underReview,
    required this.evaluated,
    required this.approved,
    required this.rejected,
    this.centerStyle,
    this.legendTextStyle,
  });

  final int pending;
  final int submitted;
  final int underReview;
  final int evaluated;
  final int approved;
  final int rejected;
  final TextStyle? centerStyle;
  final TextStyle? legendTextStyle;

  int get _total => pending + submitted + underReview + evaluated + approved + rejected;

  @override
  Widget build(BuildContext context) {
    final int safeTotal = _total.clamp(1, 1 << 20).toInt();
    final legendStyle = legendTextStyle ?? const TextStyle(fontSize: 12);
    return Row(
      children: <Widget>[
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.78,
            child: CustomPaint(
              painter: _IdeaStatusDonutPainter(
                pendingPct: pending / safeTotal,
                submittedPct: submitted / safeTotal,
                reviewPct: underReview / safeTotal,
                evaluatedPct: evaluated / safeTotal,
                approvedPct: approved / safeTotal,
                rejectedPct: rejected / safeTotal,
              ),
              child: Center(
                child: Text(
                  '$_total',
                  style: centerStyle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LegendRow(color: StatusStyles.submitted, label: 'Pending $pending', style: legendStyle),
                const SizedBox(height: 6),
                _LegendRow(color: StatusStyles.submittedChart, label: 'Submitted $submitted', style: legendStyle),
                const SizedBox(height: 6),
                _LegendRow(color: StatusStyles.underReview, label: 'Under Review $underReview', style: legendStyle),
                const SizedBox(height: 6),
                _LegendRow(color: StatusStyles.evaluated, label: 'Evaluated $evaluated', style: legendStyle),
                const SizedBox(height: 6),
                _LegendRow(color: StatusStyles.approved, label: 'Approved $approved', style: legendStyle),
                const SizedBox(height: 6),
                _LegendRow(color: StatusStyles.rejected, label: 'Rejected $rejected', style: legendStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IdeaStatusDonutPainter extends CustomPainter {
  const _IdeaStatusDonutPainter({
    required this.pendingPct,
    required this.submittedPct,
    required this.reviewPct,
    required this.evaluatedPct,
    required this.approvedPct,
    required this.rejectedPct,
  });

  final double pendingPct;
  final double submittedPct;
  final double reviewPct;
  final double evaluatedPct;
  final double approvedPct;
  final double rejectedPct;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.shortestSide * 0.31);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    double start = -math.pi / 2;

    void arc(double pct, Color color) {
      if (pct <= 0) return;
      final sweep = math.pi * 2 * pct;
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    arc(pendingPct, StatusStyles.submitted);
    arc(submittedPct, StatusStyles.submittedChart);
    arc(reviewPct, StatusStyles.underReview);
    arc(evaluatedPct, StatusStyles.evaluated);
    arc(approvedPct, StatusStyles.approved);
    arc(rejectedPct, StatusStyles.rejected);
  }

  @override
  bool shouldRepaint(covariant _IdeaStatusDonutPainter oldDelegate) {
    return oldDelegate.pendingPct != pendingPct ||
        oldDelegate.submittedPct != submittedPct ||
        oldDelegate.reviewPct != reviewPct ||
        oldDelegate.evaluatedPct != evaluatedPct ||
        oldDelegate.approvedPct != approvedPct ||
        oldDelegate.rejectedPct != rejectedPct;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.style,
  });

  final Color color;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
      ],
    );
  }
}
