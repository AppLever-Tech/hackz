import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'certificate_sample_a_fonts.dart';
import 'certificate_sample_a_visual_variant.dart';

/// Sample A typography and colors (requires embedded fonts).
abstract final class CertificateSampleATheme {
  static const PdfColor navy = PdfColor.fromInt(0xFF0B1F3A);
  static const PdfColor ink = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor muted = PdfColor.fromInt(0xFF475569);
  static const PdfColor ivory = PdfColor.fromInt(0xFFFCF8F0);
  static const PdfColor innerLine = PdfColor.fromInt(0xFFCBD5E1);

  static pw.TextStyle serifHeadline(CertificateSampleAFonts fonts, {double size = 30}) => pw.TextStyle(
        font: fonts.serifBold,
        fontSize: size,
        letterSpacing: 1.2,
        color: navy,
      );

  static pw.TextStyle serifSubhead(CertificateVisualVariant variant, CertificateSampleAFonts fonts) =>
      pw.TextStyle(
        font: fonts.serifSemiBold,
        fontSize: 16,
        letterSpacing: 2.4,
        color: variant.accent,
      );

  static pw.TextStyle sansBody(CertificateSampleAFonts fonts, {double size = 11}) => pw.TextStyle(
        font: fonts.sansRegular,
        fontSize: size,
        color: muted,
        lineSpacing: 1.45,
      );

  static pw.TextStyle sansBold(CertificateSampleAFonts fonts, {double size = 11}) => pw.TextStyle(
        font: fonts.sansBold,
        fontSize: size,
        color: ink,
        lineSpacing: 1.45,
      );

  static pw.TextStyle scriptRecipient(CertificateSampleAFonts fonts, double size) => pw.TextStyle(
        font: fonts.script,
        fontSize: size,
        color: navy,
      );

  static pw.TextStyle orgHeader(CertificateSampleAFonts fonts) => pw.TextStyle(
        font: fonts.sansSemiBold,
        fontSize: 9.5,
        color: navy,
        letterSpacing: 0.3,
      );

  static pw.TextStyle signatoryName(CertificateSampleAFonts fonts) => pw.TextStyle(
        font: fonts.sansSemiBold,
        fontSize: 9,
        color: ink,
      );

  static pw.TextStyle signatoryTitle(CertificateSampleAFonts fonts) => pw.TextStyle(
        font: fonts.sansRegular,
        fontSize: 8,
        color: muted,
      );

  static pw.TextStyle footerTagline(CertificateSampleAFonts fonts) => pw.TextStyle(
        font: fonts.sansSemiBold,
        fontSize: 7.5,
        letterSpacing: 1.8,
        color: muted,
      );

  static double recipientFontSize(String name) {
    final int len = name.trim().length;
    if (len <= 22) return 38;
    if (len <= 32) return 34;
    if (len <= 44) return 30;
    return 26;
  }

  static double bodyFontSize(String combined) {
    final int len = combined.length;
    if (len <= 180) return 11;
    if (len <= 260) return 10;
    return 9.5;
  }
}
