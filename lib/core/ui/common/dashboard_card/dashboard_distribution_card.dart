import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard_bounded_body.dart';
import 'dashboard_card_headers.dart';
import 'dashboard_layout_tokens.dart';

/// One slice in a dashboard donut distribution card.
class DashboardDonutSegment {
  const DashboardDonutSegment({
    required this.label,
    required this.count,
    required this.color,
    this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData? icon;
}

enum DashboardDonutVariant {
  platform,
  department,
}

/// Donut chart with scrollable legend for fixed-height dashboard panels.
class DashboardDistributionCard extends StatelessWidget {
  const DashboardDistributionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.segments,
    this.centerLabel,
    this.variant = DashboardDonutVariant.platform,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final List<DashboardDonutSegment> segments;
  final String? centerLabel;
  final DashboardDonutVariant variant;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final List<DashboardDonutSegment> visible =
        segments.where((DashboardDonutSegment s) => s.count > 0).toList(growable: false);
    final int total = segments.fold<int>(0, (int sum, DashboardDonutSegment s) => sum + s.count);

    return DashboardBoundedBody(
      headers: DashboardCardHeaders.sectionTitle(
        title: title,
        subtitle: subtitle,
        subtitleColor: subtitleColor ?? (variant == DashboardDonutVariant.platform ? const Color(0xFF64748B) : const Color(0xFF64748B)),
      ),
      bodyBuilder: ({required bool expandVertically}) {
        if (total == 0) {
          return variant == DashboardDonutVariant.platform
              ? const Align(alignment: Alignment.topLeft, child: Text('No distribution data yet'))
              : const Center(child: Text('No distribution data yet'));
        }
        return _DonutAndLegend(
          segments: visible,
          total: total,
          centerLabel: centerLabel,
          scrollLegend: expandVertically,
          variant: variant,
        );
      },
    );
  }
}

class _DonutAndLegend extends StatelessWidget {
  const _DonutAndLegend({
    required this.segments,
    required this.total,
    required this.centerLabel,
    required this.scrollLegend,
    required this.variant,
  });

  final List<DashboardDonutSegment> segments;
  final int total;
  final String? centerLabel;
  final bool scrollLegend;
  final DashboardDonutVariant variant;

  double get _donutSize => variant == DashboardDonutVariant.platform
      ? DashboardLayoutTokens.donutSizePlatform
      : DashboardLayoutTokens.donutSizeDepartment;

  @override
  Widget build(BuildContext context) {
    final Widget legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments.map(_legendRow).toList(growable: false),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: _donutSize,
          height: _donutSize,
          child: CustomPaint(
            painter: _DonutPainter(segments: segments, total: total, variant: variant),
            child: Center(
              child: Text(
                centerLabel ?? '$total',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: variant == DashboardDonutVariant.platform ? 18 : 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: scrollLegend
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: legend,
                )
              : legend,
        ),
      ],
    );
  }

  Widget _legendRow(DashboardDonutSegment segment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: variant == DashboardDonutVariant.platform ? 9 : 10,
            height: variant == DashboardDonutVariant.platform ? 9 : 10,
            decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          if (segment.icon != null) ...<Widget>[
            Icon(segment.icon, size: 14, color: segment.color),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
          ),
          Text(
            '${segment.count}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.segments,
    required this.total,
    required this.variant,
  });

  final List<DashboardDonutSegment> segments;
  final int total;
  final DashboardDonutVariant variant;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    if (variant == DashboardDonutVariant.platform) {
      final Paint bg = Paint()
        ..color = const Color(0xFFE8ECF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect.deflate(14), 0, 6.28318, false, bg);
      if (total <= 0) return;
      double start = -1.5708;
      for (final DashboardDonutSegment segment in segments) {
        if (segment.count <= 0) continue;
        final double sweep = (segment.count / total) * 6.28318;
        final Paint paint = Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(rect.deflate(14), start, sweep, false, paint);
        start += sweep;
      }
      return;
    }

    final int safeTotal = math.max(1, total);
    double start = -math.pi / 2;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    for (final DashboardDonutSegment segment in segments.where((DashboardDonutSegment s) => s.count > 0)) {
      final double sweep = (segment.count / safeTotal) * math.pi * 2;
      paint.color = segment.color;
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.total != total || oldDelegate.variant != variant;
}
