import 'package:pdf/widgets.dart' as pw;

import 'certificate_pdf_assets.dart';
import 'certificate_fonts.dart';

/// Cached fonts + graphics for Sample A (shared across batch generation).
class CertificateSampleARenderContext {
  CertificateSampleARenderContext._({
    required this.fonts,
    this.participationBackground,
    this.paperTexture,
    this.academicWatermark,
    this.navyCornerTopLeft,
    this.navyCornerBottomRight,
    this.goldRibbonsTopLeft,
    this.goldRibbonsBottomRight,
    this.silverRibbonsTopLeft,
    this.silverRibbonsBottomRight,
    this.dividerGold,
    this.dividerSilver,
    this.trophyGold,
    this.medalSilver,
    this.laurelsGold,
    this.laurelsSilver,
  });

  final CertificateFonts fonts;
  final pw.MemoryImage? participationBackground;
  final pw.MemoryImage? paperTexture;
  final pw.MemoryImage? academicWatermark;
  final pw.MemoryImage? navyCornerTopLeft;
  final pw.MemoryImage? navyCornerBottomRight;
  final pw.MemoryImage? goldRibbonsTopLeft;
  final pw.MemoryImage? goldRibbonsBottomRight;
  final pw.MemoryImage? silverRibbonsTopLeft;
  final pw.MemoryImage? silverRibbonsBottomRight;
  final pw.MemoryImage? dividerGold;
  final pw.MemoryImage? dividerSilver;
  final pw.MemoryImage? trophyGold;
  final pw.MemoryImage? medalSilver;
  final pw.MemoryImage? laurelsGold;
  final pw.MemoryImage? laurelsSilver;

  static CertificateSampleARenderContext? _cache;

  static Future<CertificateSampleARenderContext> load() async {
    final CertificateSampleARenderContext? cached = _cache;
    if (cached != null) return cached;

    final CertificateFonts fonts = await CertificateFonts.load();
    final CertificateSampleARenderContext ctx = CertificateSampleARenderContext._(
      fonts: fonts,
      participationBackground:
          await CertificatePdfAssets.tryImage('assets/certificate/common/participation_background.png'),
      paperTexture: await CertificatePdfAssets.tryImage('assets/certificate/common/paper_texture.png'),
      academicWatermark: await CertificatePdfAssets.tryImage('assets/certificate/common/academic_watermark.png'),
      navyCornerTopLeft: await CertificatePdfAssets.tryImage('assets/certificate/common/navy_corner_tl.png'),
      navyCornerBottomRight: await CertificatePdfAssets.tryImage('assets/certificate/common/navy_corner_br.png'),
      goldRibbonsTopLeft: await CertificatePdfAssets.tryImage('assets/certificate/common/gold_ribbons_tl.png'),
      goldRibbonsBottomRight: await CertificatePdfAssets.tryImage('assets/certificate/common/gold_ribbons_br.png'),
      silverRibbonsTopLeft: await CertificatePdfAssets.tryImage('assets/certificate/common/silver_ribbons_tl.png'),
      silverRibbonsBottomRight: await CertificatePdfAssets.tryImage('assets/certificate/common/silver_ribbons_br.png'),
      dividerGold: await CertificatePdfAssets.tryImage('assets/certificate/common/decorative_divider_gold.png'),
      dividerSilver: await CertificatePdfAssets.tryImage('assets/certificate/common/decorative_divider_silver.png'),
      trophyGold: await CertificatePdfAssets.tryImage('assets/certificate/winner/trophy_gold.png'),
      medalSilver: await CertificatePdfAssets.tryImage('assets/certificate/runner_up/medal_silver.png'),
      laurelsGold: await CertificatePdfAssets.tryImage('assets/certificate/winner/laurels_gold.png'),
      laurelsSilver: await CertificatePdfAssets.tryImage('assets/certificate/runner_up/laurels_silver.png'),
    );
    _cache = ctx;
    return ctx;
  }
}
