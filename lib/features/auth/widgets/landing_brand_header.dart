import 'package:flutter/material.dart';

import '../../../core/theme/auth_theme.dart';

/// Logo and ambient brand shapes for mobile landing / auth entry.
class LandingBrandHeader extends StatelessWidget {
  const LandingBrandHeader({
    super.key,
    this.logoHeight = 120,
    this.showAmbientShapes = true,
  });

  final double logoHeight;
  final bool showAmbientShapes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: logoHeight + (showAmbientShapes ? 28 : 0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          if (showAmbientShapes) const _AmbientShapes(),
          Image.asset(
            'assets/images/hackz_logo.png',
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _AmbientShapes extends StatelessWidget {
  const _AmbientShapes();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(top: -8, left: -24, child: _GlowOrb(size: 56, color: Color(0x336A38FF))),
        Positioned(top: 12, right: -18, child: _GlowOrb(size: 44, color: Color(0x33FF8C2B))),
        Positioned(bottom: 0, left: 40, child: _GlowOrb(size: 36, color: Color(0x220EA5E9))),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

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

/// Title block below the logo on mobile landing.
class LandingTitleBlock extends StatelessWidget {
  const LandingTitleBlock({
    super.key,
    this.title = 'Hackz',
    this.tagline = 'Build • Collaborate • Innovate',
  });

  final String title;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(title, textAlign: TextAlign.center, style: AuthTheme.titleStyle),
        const SizedBox(height: 8),
        Text(tagline, textAlign: TextAlign.center, style: AuthTheme.subtitleStyle),
      ],
    );
  }
}
