import 'dart:io';
import 'dart:typed_data';

import 'package:hackz/core/branding/hackz_brand_assets.dart';
import 'package:hackz/core/branding/hackz_brand_image_key.dart';

/// Rewrites bundled brand PNGs with real alpha (keys opaque black/white backgrounds).
void main() {
  for (final String path in <String>[
    HackzBrandAssets.primaryLogo,
    HackzBrandAssets.launcherLogo,
    HackzBrandAssets.symbol,
    HackzBrandAssets.loadingSymbol,
    HackzBrandAssets.loadingHLayer,
    HackzBrandAssets.loadingOrbitLayer,
  ]) {
    final File file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Missing: $path');
      exitCode = 1;
      continue;
    }
    final Uint8List raw = file.readAsBytesSync();
    final Uint8List keyed = HackzBrandImageKey.pngWithTransparentBackground(raw);
    file.writeAsBytesSync(keyed);
    stdout.writeln('Keyed background: $path (${keyed.length} bytes)');
  }
}
