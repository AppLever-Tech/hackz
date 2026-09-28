import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_pdf_assets.dart';
import 'package:image/image.dart' as img;

void main() {
  test('memoryImageForCertificateEmbed keys near-white background pixels', () {
    final img.Image source = img.Image(width: 4, height: 4, numChannels: 3);
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        source.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    source.setPixelRgb(2, 2, 10, 10, 10);

    final Uint8List jpeg = Uint8List.fromList(img.encodeJpg(source));
    final image = CertificatePdfAssets.memoryImageForCertificateEmbed(jpeg);
    expect(image, isNotNull);
  });
}
