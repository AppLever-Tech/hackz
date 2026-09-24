import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hackz_brand_assets.dart';
import 'hackz_brand_image_cache.dart';

/// Branded loading: stationary H with rotating orbit + dot.
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
  MemoryImage? _hImage;
  MemoryImage? _orbitImage;
  bool _layersReady = false;

  @override
  void initState() {
    super.initState();
    _orbitSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _loadLayers();
  }

  Future<void> _loadLayers() async {
    final MemoryImage? h = await HackzBrandImageCache.memoryImage(HackzBrandAssets.loadingHLayer);
    final MemoryImage? orbit = await HackzBrandImageCache.memoryImage(HackzBrandAssets.loadingOrbitLayer);
    if (!mounted) return;
    if (h != null && orbit != null) {
      setState(() {
        _hImage = h;
        _orbitImage = orbit;
        _layersReady = true;
      });
      _orbitSpin.repeat();
      return;
    }
    final MemoryImage? fallback = await HackzBrandImageCache.memoryImage(HackzBrandAssets.loadingSymbol);
    if (!mounted) return;
    setState(() {
      _hImage = fallback;
      _orbitImage = null;
      _layersReady = fallback != null;
    });
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
        child: !_layersReady
            ? const SizedBox.shrink()
            : _orbitImage != null
                ? _layeredAnimation()
                : _image(_hImage!),
      ),
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
            _image(_hImage!),
            Transform.rotate(
              angle: _orbitSpin.value * 2 * math.pi,
              child: _image(_orbitImage!),
            ),
          ],
        );
      },
    );
  }

  Widget _image(MemoryImage image) {
    return Image(
      image: image,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Loading',
      gaplessPlayback: true,
    );
  }
}
