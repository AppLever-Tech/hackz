import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Shared certificate asset loading (Hackz logo + Sample A graphics).
abstract final class CertificatePdfAssets {
  CertificatePdfAssets._();

  static pw.MemoryImage? _hackzLogoCache;
  static final Map<String, pw.MemoryImage> _imageCache = <String, pw.MemoryImage>{};

  static Future<pw.MemoryImage?> loadHackzLogo() async {
    if (_hackzLogoCache != null) return _hackzLogoCache;
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
    final pw.MemoryImage? cached = _imageCache[assetPath];
    if (cached != null) return cached;
    final ByteData data = await rootBundle.load(assetPath);
    final pw.MemoryImage image = pw.MemoryImage(data.buffer.asUint8List());
    _imageCache[assetPath] = image;
    return image;
  }

  static pw.MemoryImage? memoryImage(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return pw.MemoryImage(Uint8List.fromList(bytes));
  }
}
