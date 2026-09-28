import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:hackz/features/exports/certificate/certificate_image_processing.dart';
import 'package:hackz/features/exports/certificate/certificate_pdf_assets.dart';
import 'package:image/image.dart' as img;

/// Synthetic raster fixtures for certificate PDF local QA (no Firebase).
abstract final class CertificateTestFixtures {
  CertificateTestFixtures._();

  /// Cream scan background (#F5F0E8) with dark ink stroke — mimics uploaded signatures.
  static Uint8List creamSignatureScanPng() {
    final img.Image source = img.Image(width: 200, height: 64);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        source.setPixelRgba(x, y, 245, 240, 232, 255);
      }
    }
    for (int x = 40; x < 160; x++) {
      source.setPixelRgba(x, 36, 25, 22, 35, 255);
      source.setPixelRgba(x, 37, 25, 22, 35, 255);
    }
    return Uint8List.fromList(img.encodePng(source));
  }

  /// Certificate ivory (#FCF8F0) background with ink.
  static Uint8List ivorySignatureScanPng() {
    final img.Image source = img.Image(width: 200, height: 64);
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        source.setPixelRgba(
          x,
          y,
          CertificateImageProcessing.paperR,
          CertificateImageProcessing.paperG,
          CertificateImageProcessing.paperB,
          255,
        );
      }
    }
    for (int x = 50; x < 150; x++) {
      source.setPixelRgba(x, 32, 15, 18, 28, 255);
    }
    return Uint8List.fromList(img.encodePng(source));
  }

  /// Loads a bundled PNG and prepares it like a college logo upload.
  static Future<Uint8List> collegeLogoFromAsset(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return CertificateImageProcessing.prepareCertificateEmbed(data.buffer.asUint8List());
  }

  static Future<Uint8List> collegeLogoFromPrimaryBrandAsset() {
    return collegeLogoFromAsset('assets/branding/hackz_symbol.png');
  }

  /// Same pipeline as [CertificateEventSignatoryConfig.toPdfSignatories].
  static Uint8List signatureBytesForPdf(Uint8List rawScanBytes) {
    return CertificateImageProcessing.prepareCertificateEmbed(rawScanBytes);
  }
}
