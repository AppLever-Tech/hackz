import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_image_processing.dart';
import 'package:image/image.dart' as img;

void main() {
  group('prepareCertificateEmbed', () {
    test('keys ivory paper and near-white scan background', () {
      final img.Image source = img.Image(width: 40, height: 20);
      for (int y = 0; y < source.height; y++) {
        for (int x = 0; x < source.width; x++) {
          source.setPixelRgba(x, y, 252, 248, 240, 255);
        }
      }
      for (int x = 10; x < 30; x++) {
        source.setPixelRgba(x, 10, 20, 18, 30, 255);
      }
      final Uint8List raw = Uint8List.fromList(img.encodePng(source));
      final Uint8List out = CertificateImageProcessing.prepareCertificateEmbed(raw);
      final img.Image? decoded = img.decodeImage(out);
      expect(decoded, isNotNull);
      expect(decoded!.getPixel(0, 0).a.toInt(), 0);
      expect(decoded.getPixel(15, 10).a.toInt(), 255);
    });

    test('keys white center when PNG has transparent edges', () {
      final img.Image source = img.Image(width: 40, height: 20, numChannels: 4);
      for (int y = 0; y < source.height; y++) {
        for (int x = 0; x < source.width; x++) {
          final int alpha = (x == 0 || y == 0 || x == 39 || y == 19) ? 0 : 255;
          source.setPixelRgba(x, y, 255, 255, 255, alpha);
        }
      }
      source.setPixelRgba(20, 10, 30, 25, 40, 255);
      final Uint8List raw = Uint8List.fromList(img.encodePng(source));
      final Uint8List out = CertificateImageProcessing.prepareCertificateEmbed(raw);
      final img.Image? decoded = img.decodeImage(out);
      expect(decoded, isNotNull);
      expect(decoded!.getPixel(20, 5).a.toInt(), 0);
      expect(decoded.getPixel(20, 10).a.toInt(), 255);
    });

    test('keys white matte but keeps logo ink', () {
      final img.Image source = img.Image(width: 10, height: 10);
      for (int y = 0; y < source.height; y++) {
        for (int x = 0; x < source.width; x++) {
          source.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
      source.setPixelRgba(5, 5, 120, 40, 200, 255);
      final Uint8List raw = Uint8List.fromList(img.encodePng(source));
      final Uint8List out = CertificateImageProcessing.prepareCertificateEmbed(raw);
      final img.Image? decoded = img.decodeImage(out);
      expect(decoded, isNotNull);
      expect(decoded!.getPixel(5, 5).a.toInt(), 255);
      expect(decoded.getPixel(0, 0).a.toInt(), 0);
    });
  });
}
