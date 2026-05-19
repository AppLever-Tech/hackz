import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Directional connector between two milestone edge points.
class JourneyConnectorSegment {
  const JourneyConnectorSegment({
    required this.from,
    required this.to,
    this.emphasis = false,
  });

  final Offset from;
  final Offset to;
  final bool emphasis;
}

/// Premium sequential-flow connectors with glow and optional pulse.
class JourneyConnectorPainter extends CustomPainter {
  JourneyConnectorPainter({
    required this.segments,
    this.pulse = 0,
  });

  final List<JourneyConnectorSegment> segments;
  final double pulse;

  static const Color _primary = Color(0xFF6A38FF);
  static const Color _secondary = Color(0x996A38FF);

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
    final bool emphasis = seg.emphasis;
    final double stroke = emphasis ? 5.2 : 4.2;
    final double headLen = emphasis ? 13 : 11;
    final double headW = emphasis ? 7.5 : 6.5;

    final Offset lineEnd = to - unit * headLen;

    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 6
      ..strokeCap = StrokeCap.round
      ..color = _primary.withValues(alpha: emphasis ? 0.14 : 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        from,
        lineEnd,
        <Color>[
          emphasis ? _primary.withValues(alpha: 0.75) : _secondary,
          emphasis ? _primary : const Color(0xFF8B5CF6),
        ],
      );

    canvas.drawLine(from, lineEnd, glow);
    canvas.drawLine(from, lineEnd, line);

    final Offset wing = Offset(-unit.dy, unit.dx) * headW;
    final Offset base = to - unit * headLen;

    canvas.drawPath(
      Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(base.dx + wing.dx, base.dy + wing.dy)
        ..lineTo(base.dx - wing.dx, base.dy - wing.dy)
        ..close(),
      Paint()..color = emphasis ? _primary : const Color(0xFF7C4DFF),
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
        Paint()..color = _primary.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant JourneyConnectorPainter old) {
    return old.pulse != pulse || old.segments != segments;
  }
}
