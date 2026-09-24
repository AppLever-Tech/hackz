import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

import 'hackz_brand_image_key.dart';

/// Decoded brand rasters with keyed backgrounds, cached for UI.
abstract final class HackzBrandImageCache {
  HackzBrandImageCache._();

  static final Map<String, MemoryImage> _memory = <String, MemoryImage>{};

  static Future<MemoryImage?> memoryImage(String assetPath) async {
    final MemoryImage? cached = _memory[assetPath];
    if (cached != null) return cached;

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List keyed = HackzBrandImageKey.pngWithTransparentBackground(data.buffer.asUint8List());
      final MemoryImage image = MemoryImage(keyed);
      _memory[assetPath] = image;
      return image;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static void clearForTests() => _memory.clear();
}
