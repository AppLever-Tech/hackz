import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'hkz_loading_theme.dart';

/// Premium rotating gradient arc loader (GPU-friendly CustomPainter).
class HkzProgressIndicator extends StatefulWidget {
  const HkzProgressIndicator({
    super.key,
    this.size = 44,
    this.strokeWidth = 3.6,
  });

  final double size;
  final double strokeWidth;

  @override
  State<HkzProgressIndicator> createState() => _HkzProgressIndicatorState();
}

class _HkzProgressIndicatorState extends State<HkzProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _spin,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              painter: _ArcLoaderPainter(
                rotation: _spin.value * 2 * math.pi,
                strokeWidth: widget.strokeWidth,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArcLoaderPainter extends CustomPainter {
  _ArcLoaderPainter({
    required this.rotation,
    required this.strokeWidth,
  });

  final double rotation;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide - strokeWidth) / 2;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6A38FF).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.sweep(
        center,
        HkzLoadingTheme.arcGradient.colors,
        <double>[0, 0.55, 1],
        TileMode.clamp,
        rotation,
        rotation + math.pi * 1.35,
      );

    const double sweep = math.pi * 1.35;
    canvas.drawArc(arcRect, rotation, sweep, false, glow);
    canvas.drawArc(arcRect, rotation, sweep, false, arc);

    final Paint dot = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final Offset tip = Offset(
      center.dx + radius * math.cos(rotation + sweep),
      center.dy + radius * math.sin(rotation + sweep),
    );
    canvas.drawCircle(tip, strokeWidth * 0.55, dot);
  }

  @override
  bool shouldRepaint(covariant _ArcLoaderPainter old) => old.rotation != rotation;
}
