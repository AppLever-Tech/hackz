import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/branding/hackz_brand_image_key.dart';
import 'package:image/image.dart' as img;

void main() {
  test('keys opaque black background to transparent alpha', () {
    final img.Image source = img.Image(width: 8, height: 8, numChannels: 3);
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        source.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    source.setPixelRgb(4, 4, 0, 180, 220);

    final Uint8List png = HackzBrandImageKey.pngWithTransparentBackground(
      Uint8List.fromList(img.encodePng(source)),
    );
    final img.Image? out = img.decodeImage(png);
    expect(out, isNotNull);
    expect(out!.numChannels, 4);
    expect(out.getPixel(0, 0).a.toInt(), 0);
    expect(out.getPixel(4, 4).a.toInt(), 255);
  });
}
