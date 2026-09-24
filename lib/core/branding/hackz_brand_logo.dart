import 'package:flutter/material.dart';

import 'hackz_brand_assets.dart';
import 'hackz_brand_image_cache.dart';

enum HackzBrandLogoVariant {
  primary,
  launcher,
  symbol,
}

/// Responsive Hackz logo — always [BoxFit.contain], never cropped or stretched.
class HackzBrandLogo extends StatelessWidget {
  const HackzBrandLogo({
    super.key,
    required this.variant,
    this.height,
    this.width,
    this.semanticLabel = 'Hackz',
  }) : assert(height != null || width != null, 'Provide height and/or width constraints.');

  final HackzBrandLogoVariant variant;
  final double? height;
  final double? width;
  final String semanticLabel;

  String get _assetPath => switch (variant) {
        HackzBrandLogoVariant.primary => HackzBrandAssets.primaryLogo,
        HackzBrandLogoVariant.launcher => HackzBrandAssets.launcherLogo,
        HackzBrandLogoVariant.symbol => HackzBrandAssets.symbol,
      };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MemoryImage?>(
      future: HackzBrandImageCache.memoryImage(_assetPath),
      builder: (BuildContext context, AsyncSnapshot<MemoryImage?> snapshot) {
        final MemoryImage? image = snapshot.data;
        if (image == null) {
          return SizedBox(width: width, height: height);
        }
        return Image(
          image: image,
          height: height,
          width: width,
          fit: BoxFit.contain,
          semanticLabel: semanticLabel,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        );
      },
    );
  }
}
