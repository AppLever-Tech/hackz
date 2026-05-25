import 'package:flutter/material.dart';

import '../../utils/sysadmin_dashboard_service.dart';
import '../common/dashboard_panel_column.dart';

class PlatformDistributionChart extends StatelessWidget {
  const PlatformDistributionChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.segments,
    this.centerLabel,
  });

  final String title;
  final String subtitle;
  final List<PlatformDistributionSegment> segments;
  final String? centerLabel;

  static const double _kDonutSize = 124;

  @override
  Widget build(BuildContext context) {
    final int total = segments.fold<int>(0, (int sum, PlatformDistributionSegment s) => sum + s.count);
    final List<PlatformDistributionSegment> visible =
        segments.where((PlatformDistributionSegment s) => s.count > 0).toList(growable: false);

    return DashboardPanelColumn(
      headers: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 14),
      ],
      listBuilder: ({required bool expandVertically}) {
        if (total == 0) {
          return const Align(
            alignment: Alignment.topLeft,
            child: Text('No distribution data yet'),
          );
        }
        return _DistributionBody(
          segments: visible,
          total: total,
          centerLabel: centerLabel,
          scrollLegend: expandVertically,
        );
      },
    );
  }
}

class _DistributionBody extends StatelessWidget {
  const _DistributionBody({
    required this.segments,
    required this.total,
    required this.centerLabel,
    required this.scrollLegend,
  });

  final List<PlatformDistributionSegment> segments;
  final int total;
  final String? centerLabel;
  final bool scrollLegend;

  @override
  Widget build(BuildContext context) {
    final Widget legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments
          .map(
            (PlatformDistributionSegment s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                    ),
                  ),
                  Text(
                    '${s.count}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: PlatformDistributionChart._kDonutSize,
          height: PlatformDistributionChart._kDonutSize,
          child: CustomPaint(
            painter: _DonutPainter(segments, total),
            child: Center(
              child: Text(
                centerLabel ?? '$total',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.segments, this.total);

  final List<PlatformDistributionSegment> segments;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint bg = Paint()
      ..color = const Color(0xFFE8ECF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(14), 0, 6.28318, false, bg);
    if (total <= 0) return;

    double start = -1.5708;
    for (final PlatformDistributionSegment segment in segments) {
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
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments || oldDelegate.total != total;
}
