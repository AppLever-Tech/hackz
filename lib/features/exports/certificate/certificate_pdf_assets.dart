import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import 'package:hackz/core/branding/hackz_brand_assets.dart';
import 'package:hackz/core/branding/hackz_brand_image_key.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

import 'certificate_image_processing.dart';

/// Shared certificate asset loading (Hackz logo + certificate graphics).
abstract final class CertificatePdfAssets {
  CertificatePdfAssets._();

  static pw.MemoryImage? _hackzLogoCache;
  static final Map<String, pw.MemoryImage> _imageCache = <String, pw.MemoryImage>{};
  static final Map<String, pw.Font> _fontCache = <String, pw.Font>{};

  /// Primary Hackz brand mark for all certificate types.
  static Future<pw.MemoryImage?> loadHackzLogo() async {
    if (_hackzLogoCache != null) return _hackzLogoCache;
    final pw.MemoryImage? logo = await tryBrandImage(HackzBrandAssets.primaryLogo);
    if (logo != null) {
      _hackzLogoCache = logo;
    }
    return logo;
  }

  /// Brand PNGs may be RGB-on-black exports; key background before PDF embed.
  static Future<pw.MemoryImage?> tryBrandImage(String assetPath) async {
    final String cacheKey = '$assetPath#brand';
    final pw.MemoryImage? cached = _imageCache[cacheKey];
    if (cached != null) return cached;
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List png = HackzBrandImageKey.pngWithTransparentBackground(data.buffer.asUint8List());
      final pw.MemoryImage image = pw.MemoryImage(png);
      _imageCache[cacheKey] = image;
      return image;
    } catch (_) {
      return null;
    }
  }

  static Future<pw.MemoryImage> requireImage(String assetPath) async {
    final pw.MemoryImage? image = await tryImage(assetPath);
    if (image == null) {
      throw FlutterError('Missing certificate asset: $assetPath');
    }
    return image;
  }

  static Future<pw.MemoryImage?> tryImage(String assetPath) async {
    final pw.MemoryImage? cached = _imageCache[assetPath];
    if (cached != null) return cached;
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final pw.MemoryImage image = pw.MemoryImage(data.buffer.asUint8List());
      _imageCache[assetPath] = image;
      return image;
    } catch (_) {
      return null;
    }
  }

  /// Header overlays must support transparency (often mis-exported as JPEG on black).
  static Future<pw.MemoryImage?> tryOverlayImage(String assetPath) async {
    final String cacheKey = '$assetPath#overlay';
    final pw.MemoryImage? cached = _imageCache[cacheKey];
    if (cached != null) return cached;
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final img.Image rgba = _overlayWithTransparentBackground(decoded);
      final Uint8List png = Uint8List.fromList(img.encodePng(rgba));
      final pw.MemoryImage image = pw.MemoryImage(png);
      _imageCache[cacheKey] = image;
      return image;
    } catch (_) {
      return null;
    }
  }

  /// Makes near-black pixels transparent (JPEG exports without an alpha channel).
  static img.Image _overlayWithTransparentBackground(img.Image source) {
    final img.Image out = img.Image(width: source.width, height: source.height, numChannels: 4);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        final img.Pixel p = source.getPixel(x, y);
        final int r = p.r.toInt();
        final int g = p.g.toInt();
        final int b = p.b.toInt();
        final int maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
        final int alpha = maxChannel < 28 ? 0 : 255;
        out.setPixelRgba(x, y, r, g, b, alpha);
      }
    }
    return out;
  }

  static Future<pw.Font> loadFontTtf(String assetPath) async {
    final pw.Font? cached = _fontCache[assetPath];
    if (cached != null) return cached;
    final ByteData data = await rootBundle.load(assetPath);
    final pw.Font font = pw.Font.ttf(data);
    _fontCache[assetPath] = font;
    return font;
  }

  static pw.MemoryImage? memoryImage(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return pw.MemoryImage(Uint8List.fromList(bytes));
  }

  /// Logos and signatures: key upload/scan paper before PDF embed.
  static pw.MemoryImage? memoryImageForCertificateEmbed(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final Uint8List png = CertificateImageProcessing.prepareCertificateEmbed(bytes);
      return pw.MemoryImage(png);
    } catch (_) {
      return pw.MemoryImage(bytes);
    }
  }
}
