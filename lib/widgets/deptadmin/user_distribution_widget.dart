import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/department_dashboard_service.dart';
import '../common/dashboard_panel_column.dart';

class UserDistributionWidget extends StatelessWidget {
  const UserDistributionWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.segments,
  });

  final String title;
  final String subtitle;
  final List<DepartmentDistributionSegment> segments;

  static const double _kDonutSize = 132;

  @override
  Widget build(BuildContext context) {
    final int total = segments.fold<int>(0, (sum, segment) => sum + segment.count);

    return DashboardPanelColumn(
      headers: <Widget>[
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
      ],
      listBuilder: ({required bool expandVertically}) {
        if (total == 0) {
          return const Center(child: Text('No distribution data yet'));
        }
        return _DistributionBody(
          segments: segments,
          total: total,
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
    required this.scrollLegend,
  });

  final List<DepartmentDistributionSegment> segments;
  final int total;
  final bool scrollLegend;

  @override
  Widget build(BuildContext context) {
    final Widget legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments
          .map(
            (segment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Icon(segment.icon, size: 14, color: segment.color),
                  const SizedBox(width: 6),
                  Text(
                    segment.label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${segment.count}',
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
          width: UserDistributionWidget._kDonutSize,
          height: UserDistributionWidget._kDonutSize,
          child: CustomPaint(
            painter: _DonutPainter(segments),
            child: Center(
              child: Text(
                '$total',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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
  _DonutPainter(this.segments);

  final List<DepartmentDistributionSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final int total = math.max(1, segments.fold<int>(0, (sum, segment) => sum + segment.count));
    double start = -math.pi / 2;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    for (final segment in segments.where((s) => s.count > 0)) {
      final sweep = (segment.count / total) * math.pi * 2;
      paint.color = segment.color;
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments;
}
