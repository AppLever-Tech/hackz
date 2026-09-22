import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Embedded certificate fonts (OFL — bundled under assets/certificate/fonts).
class CertificateSampleAFonts {
  CertificateSampleAFonts._({
    required this.serifBold,
    required this.serifSemiBold,
    required this.script,
    required this.sansRegular,
    required this.sansSemiBold,
    required this.sansBold,
  });

  final pw.Font serifBold;
  final pw.Font serifSemiBold;
  final pw.Font script;
  final pw.Font sansRegular;
  final pw.Font sansSemiBold;
  final pw.Font sansBold;

  static CertificateSampleAFonts? _cache;

  static Future<CertificateSampleAFonts> load() async {
    final CertificateSampleAFonts? cached = _cache;
    if (cached != null) return cached;
    final CertificateSampleAFonts loaded = CertificateSampleAFonts._(
      serifBold: await _ttf('assets/certificate/fonts/CormorantGaramond-Bold.ttf'),
      serifSemiBold: await _ttf('assets/certificate/fonts/CormorantGaramond-SemiBold.ttf'),
      script: await _ttf('assets/certificate/fonts/GreatVibes-Regular.ttf'),
      sansRegular: await _ttf('assets/certificate/fonts/SourceSans3-Regular.ttf'),
      sansSemiBold: await _ttf('assets/certificate/fonts/SourceSans3-SemiBold.ttf'),
      sansBold: await _ttf('assets/certificate/fonts/SourceSans3-Bold.ttf'),
    );
    _cache = loaded;
    return loaded;
  }

  static Future<pw.Font> _ttf(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  }
}
