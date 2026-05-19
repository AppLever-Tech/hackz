import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Directional connector between two milestone edge points.
class JourneyConnectorSegment {
  const JourneyConnectorSegment({
    required this.from,
    required this.to,
  });

  final Offset from;
  final Offset to;
}

/// Premium sequential-flow connectors with glow and optional pulse.
class JourneyConnectorPainter extends CustomPainter {
  JourneyConnectorPainter({
    required this.segments,
    this.pulse = 0,
  });

  final List<JourneyConnectorSegment> segments;
  final double pulse;

  static const Color _strokeStart = Color(0x886A38FF);
  static const Color _strokeEnd = Color(0xFF8B5CF6);
  static const Color _arrowFill = Color(0xFF7C4DFF);
  static const double _strokeWidth = 4.2;
  static const double _headLen = 11;
  static const double _headW = 6.5;

  @override
  void paint(Canvas canvas, Size size) {
    for (final JourneyConnectorSegment seg in segments) {
      _paintSegment(canvas, seg);
    }
  }

  void _paintSegment(Canvas canvas, JourneyConnectorSegment seg) {
    final Offset from = seg.from;
    final Offset to = seg.to;
    final Offset delta = to - from;
    if (delta.distance < 2) return;

    final Offset unit = delta / delta.distance;
    final Offset lineEnd = to - unit * _headLen;

    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6A38FF).withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        from,
        lineEnd,
        const <Color>[_strokeStart, _strokeEnd],
      );

    canvas.drawLine(from, lineEnd, glow);
    canvas.drawLine(from, lineEnd, line);

    final Offset wing = Offset(-unit.dy, unit.dx) * _headW;
    final Offset base = to - unit * _headLen;

    canvas.drawPath(
      Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(base.dx + wing.dx, base.dy + wing.dy)
        ..lineTo(base.dx - wing.dx, base.dy - wing.dy)
        ..close(),
      Paint()..color = _arrowFill,
    );

    if (pulse > 0) {
      final Offset pulsePos = Offset.lerp(from, to, pulse)!;
      canvas.drawCircle(
        pulsePos,
        3.2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(
        pulsePos,
        5,
        Paint()..color = const Color(0xFF6A38FF).withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant JourneyConnectorPainter old) {
    return old.pulse != pulse || old.segments != segments;
  }
}
