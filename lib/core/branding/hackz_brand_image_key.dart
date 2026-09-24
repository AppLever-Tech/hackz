import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Keys mis-exported brand PNG/JPEG backgrounds (opaque black or white) to alpha.
abstract final class HackzBrandImageKey {
  HackzBrandImageKey._();

  static const int _darkThreshold = 28;
  static const int _lightThreshold = 242;

  static Uint8List pngWithTransparentBackground(Uint8List bytes) {
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    if (decoded.numChannels == 4 && _hasMeaningfulTransparency(decoded)) {
      return bytes;
    }
    final img.Image rgba = _keyBackground(decoded);
    return Uint8List.fromList(img.encodePng(rgba));
  }

  static bool _hasMeaningfulTransparency(img.Image source) {
    int transparent = 0;
    final int stepX = source.width > 64 ? source.width ~/ 32 : 1;
    final int stepY = source.height > 64 ? source.height ~/ 32 : 1;
    for (int y = 0; y < source.height; y += stepY) {
      for (int x = 0; x < source.width; x += stepX) {
        if (source.getPixel(x, y).a.toInt() < 16) transparent++;
      }
    }
    return transparent > 8;
  }

  static img.Image _keyBackground(img.Image source) {
    final img.Image out = img.Image(width: source.width, height: source.height, numChannels: 4);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final img.Pixel p = source.getPixel(x, y);
        final int r = p.r.toInt();
        final int g = p.g.toInt();
        final int b = p.b.toInt();
        final int maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final int minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
        final int alpha = maxChannel < _darkThreshold || minChannel > _lightThreshold ? 0 : 255;
        out.setPixelRgba(x, y, r, g, b, alpha);
      }
    }
    return out;
  }
}
