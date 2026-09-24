import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hackz_brand_assets.dart';

/// Branded loading mark for overlays and full-screen waits.
///
/// When separate H and orbit layers are configured on [HackzBrandAssets], only
/// the orbit layer rotates. Otherwise the approved [loadingSymbol] is shown
/// static (the raster includes H + orbit on one layer).
class HackzBrandLoadingIndicator extends StatefulWidget {
  const HackzBrandLoadingIndicator({
    super.key,
    this.size = 56,
  });

  final double size;

  @override
  State<HackzBrandLoadingIndicator> createState() => _HackzBrandLoadingIndicatorState();
}

class _HackzBrandLoadingIndicatorState extends State<HackzBrandLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitSpin;

  bool get _canAnimateOrbit =>
      HackzBrandAssets.loadingHLayer != null && HackzBrandAssets.loadingOrbitLayer != null;

  @override
  void initState() {
    super.initState();
    _orbitSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (_canAnimateOrbit) {
      _orbitSpin.repeat();
    }
  }

  @override
  void dispose() {
    _orbitSpin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: _canAnimateOrbit ? _layeredAnimation() : _staticLoadingSymbol(),
      ),
    );
  }

  Widget _staticLoadingSymbol() {
    return Image.asset(
      HackzBrandAssets.loadingSymbol,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Loading',
    );
  }

  Widget _layeredAnimation() {
    return AnimatedBuilder(
      animation: _orbitSpin,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            Image.asset(
              HackzBrandAssets.loadingHLayer!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            Transform.rotate(
              angle: _orbitSpin.value * 2 * math.pi,
              child: Image.asset(
                HackzBrandAssets.loadingOrbitLayer!,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        );
      },
    );
  }
}
