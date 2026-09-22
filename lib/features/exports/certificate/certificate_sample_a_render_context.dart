import 'package:pdf/widgets.dart' as pw;

import 'certificate_pdf_assets.dart';
import 'certificate_sample_a_fonts.dart';

/// Cached fonts + graphics for Sample A (shared across batch generation).
class CertificateSampleARenderContext {
  CertificateSampleARenderContext._({
    required this.fonts,
    required this.paperTexture,
    required this.academicWatermark,
    required this.navyCornerTopLeft,
    required this.navyCornerBottomRight,
    required this.goldRibbonsTopLeft,
    required this.goldRibbonsBottomRight,
    required this.silverRibbonsTopLeft,
    required this.silverRibbonsBottomRight,
    required this.dividerGold,
    required this.dividerSilver,
    required this.trophyGold,
    required this.medalSilver,
    required this.laurelsGold,
    required this.laurelsSilver,
  });

  final CertificateSampleAFonts fonts;
  final pw.MemoryImage paperTexture;
  final pw.MemoryImage academicWatermark;
  final pw.MemoryImage navyCornerTopLeft;
  final pw.MemoryImage navyCornerBottomRight;
  final pw.MemoryImage goldRibbonsTopLeft;
  final pw.MemoryImage goldRibbonsBottomRight;
  final pw.MemoryImage silverRibbonsTopLeft;
  final pw.MemoryImage silverRibbonsBottomRight;
  final pw.MemoryImage dividerGold;
  final pw.MemoryImage dividerSilver;
  final pw.MemoryImage trophyGold;
  final pw.MemoryImage medalSilver;
  final pw.MemoryImage laurelsGold;
  final pw.MemoryImage laurelsSilver;

  static CertificateSampleARenderContext? _cache;

  static Future<CertificateSampleARenderContext> load() async {
    final CertificateSampleARenderContext? cached = _cache;
    if (cached != null) return cached;

    final CertificateSampleAFonts fonts = await CertificateSampleAFonts.load();
    final CertificateSampleARenderContext ctx = CertificateSampleARenderContext._(
      fonts: fonts,
      paperTexture: await CertificatePdfAssets.requireImage('assets/certificate/common/paper_texture.png'),
      academicWatermark: await CertificatePdfAssets.requireImage('assets/certificate/common/academic_watermark.png'),
      navyCornerTopLeft: await CertificatePdfAssets.requireImage('assets/certificate/common/navy_corner_tl.png'),
      navyCornerBottomRight: await CertificatePdfAssets.requireImage('assets/certificate/common/navy_corner_br.png'),
      goldRibbonsTopLeft: await CertificatePdfAssets.requireImage('assets/certificate/common/gold_ribbons_tl.png'),
      goldRibbonsBottomRight: await CertificatePdfAssets.requireImage('assets/certificate/common/gold_ribbons_br.png'),
      silverRibbonsTopLeft: await CertificatePdfAssets.requireImage('assets/certificate/common/silver_ribbons_tl.png'),
      silverRibbonsBottomRight: await CertificatePdfAssets.requireImage('assets/certificate/common/silver_ribbons_br.png'),
      dividerGold: await CertificatePdfAssets.requireImage('assets/certificate/common/decorative_divider_gold.png'),
      dividerSilver: await CertificatePdfAssets.requireImage('assets/certificate/common/decorative_divider_silver.png'),
      trophyGold: await CertificatePdfAssets.requireImage('assets/certificate/winner/trophy_gold.png'),
      medalSilver: await CertificatePdfAssets.requireImage('assets/certificate/runner_up/medal_silver.png'),
      laurelsGold: await CertificatePdfAssets.requireImage('assets/certificate/winner/laurels_gold.png'),
      laurelsSilver: await CertificatePdfAssets.requireImage('assets/certificate/runner_up/laurels_silver.png'),
    );
    _cache = ctx;
    return ctx;
  }
}
