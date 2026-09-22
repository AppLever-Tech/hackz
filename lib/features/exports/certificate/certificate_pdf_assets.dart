import 'dart:typed_data';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Shared certificate asset loading (Hackz logo + certificate graphics).
abstract final class CertificatePdfAssets {
  CertificatePdfAssets._();

  static pw.MemoryImage? _hackzLogoCache;
  static final Map<String, pw.MemoryImage> _imageCache = <String, pw.MemoryImage>{};
  static final Map<String, pw.Font> _fontCache = <String, pw.Font>{};

  static const String certificateHackzLogoPath = 'assets/certificate/common/hackz_certificate_logo.png';

  /// Certificate PDFs prefer [certificateHackzLogoPath], then the app logo.
  static Future<pw.MemoryImage?> loadHackzLogo() async {
    if (_hackzLogoCache != null) return _hackzLogoCache;
    final pw.MemoryImage? certificateLogo = await tryImage(certificateHackzLogoPath);
    if (certificateLogo != null) {
      _hackzLogoCache = certificateLogo;
      return certificateLogo;
    }
    try {
      final ByteData data = await rootBundle.load('assets/images/hackz_logo.png');
      final pw.MemoryImage image = pw.MemoryImage(data.buffer.asUint8List());
      _hackzLogoCache = image;
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
}
