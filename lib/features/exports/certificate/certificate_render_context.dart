import 'package:pdf/widgets.dart' as pw;

import 'certificate_pdf_assets.dart';
import 'certificate_fonts.dart';

/// Cached fonts + graphics for certificate PDF generation (shared across batches).
class CertificateRenderContext {
  CertificateRenderContext._({
    required this.fonts,
    this.participationBackground,
    this.winnerOverlay,
    this.runnerUpOverlay,
  });

  final CertificateFonts fonts;
  final pw.MemoryImage? participationBackground;
  final pw.MemoryImage? winnerOverlay;
  final pw.MemoryImage? runnerUpOverlay;

  static CertificateRenderContext? _cache;

  static Future<CertificateRenderContext> load() async {
    final CertificateRenderContext? cached = _cache;
    if (cached != null) return cached;

    final CertificateFonts fonts = await CertificateFonts.load();
    final CertificateRenderContext ctx = CertificateRenderContext._(
      fonts: fonts,
      participationBackground:
          await CertificatePdfAssets.tryImage('assets/certificate/common/participation_background.png'),
      winnerOverlay:
          await CertificatePdfAssets.tryOverlayImage('assets/certificate/overlays/winner_overlay.png'),
      runnerUpOverlay:
          await CertificatePdfAssets.tryOverlayImage('assets/certificate/overlays/runner_up_overlay.png'),
    );
    _cache = ctx;
    return ctx;
  }
}
