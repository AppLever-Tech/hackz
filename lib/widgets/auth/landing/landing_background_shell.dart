import 'package:flutter/material.dart';

import '../../../theme/auth_theme.dart';

/// Full-page gradient shell with grid lines and radial glows (no images).
class LandingBackgroundShell extends StatelessWidget {
  const LandingBackgroundShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AuthTheme.pageBackground),
          ),
          const _InnovationGridLayer(),
          const _AmbientLayer(),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _InnovationGridLayer extends StatelessWidget {
  const _InnovationGridLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InnovationGridPainter(),
      size: Size.infinite,
    );
  }
}

class _InnovationGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double step = 48;
    final Paint line = Paint()
      ..color = const Color(0x0D6A38FF)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    final Paint radial = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0x186A38FF),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.72, size.height * 0.28),
        radius: size.width * 0.35,
      ));
    canvas.drawRect(Offset.zero & size, radial);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AmbientLayer extends StatelessWidget {
  const _AmbientLayer();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(top: -60, right: -30, child: _GlowOrb(180, Color(0x206A38FF))),
        Positioned(top: 100, left: -50, child: _GlowOrb(130, Color(0x14FF8C2B))),
        Positioned(bottom: 60, right: 60, child: _GlowOrb(110, Color(0x120EA5E9))),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
