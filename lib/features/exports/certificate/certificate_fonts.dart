import 'package:pdf/widgets.dart' as pw;

import 'certificate_pdf_assets.dart';

/// Embedded certificate PDF fonts (loaded once per generation session).
class CertificateFonts {
  CertificateFonts._({
    required this.headingSemiBold,
    required this.headingBold,
    required this.recipientScript,
    required this.bodyRegular,
    required this.bodyMedium,
    required this.bodySemiBold,
    required this.bodyBold,
  });

  final pw.Font headingSemiBold;
  final pw.Font headingBold;
  final pw.Font recipientScript;
  final pw.Font bodyRegular;
  final pw.Font bodyMedium;
  final pw.Font bodySemiBold;
  final pw.Font bodyBold;

  static CertificateFonts? _cache;

  static const String _dir = 'assets/fonts/certificates';

  static Future<CertificateFonts> load() async {
    final CertificateFonts? cached = _cache;
    if (cached != null) return cached;

    final List<pw.Font> loaded = await Future.wait<pw.Font>(<Future<pw.Font>>[
      CertificatePdfAssets.loadFontTtf('$_dir/PlayfairDisplay-SemiBold.ttf'),
      CertificatePdfAssets.loadFontTtf('$_dir/PlayfairDisplay-Bold.ttf'),
      CertificatePdfAssets.loadFontTtf('$_dir/GreatVibes-Regular.ttf'),
      CertificatePdfAssets.loadFontTtf('$_dir/Inter_28pt-Regular.ttf'),
      CertificatePdfAssets.loadFontTtf('$_dir/Inter_28pt-Medium.ttf'),
      CertificatePdfAssets.loadFontTtf('$_dir/Inter_28pt-SemiBold.ttf'),
      CertificatePdfAssets.loadFontTtf('$_dir/Inter_28pt-Bold.ttf'),
    ]);

    final CertificateFonts fonts = CertificateFonts._(
      headingSemiBold: loaded[0],
      headingBold: loaded[1],
      recipientScript: loaded[2],
      bodyRegular: loaded[3],
      bodyMedium: loaded[4],
      bodySemiBold: loaded[5],
      bodyBold: loaded[6],
    );
    _cache = fonts;
    return fonts;
  }
}
