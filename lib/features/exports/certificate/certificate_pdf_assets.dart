import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Shared certificate asset loading (Hackz logo, optional org bytes).
abstract final class CertificatePdfAssets {
  CertificatePdfAssets._();

  static pw.MemoryImage? _hackzLogoCache;

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

  static pw.MemoryImage? memoryImage(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return pw.MemoryImage(Uint8List.fromList(bytes));
  }
}
