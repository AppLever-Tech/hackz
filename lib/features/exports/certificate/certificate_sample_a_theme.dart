import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'certificate_fonts.dart';
import 'certificate_sample_a_visual_variant.dart';

/// Sample A typography (Playfair / Great Vibes / Inter via [CertificateFonts]).
abstract final class CertificateSampleATheme {
  static const PdfColor navy = PdfColor.fromInt(0xFF0B1F3A);
  static const PdfColor ink = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor muted = PdfColor.fromInt(0xFF475569);
  static const PdfColor ivory = PdfColor.fromInt(0xFFFCF8F0);
  static const PdfColor innerLine = PdfColor.fromInt(0xFFCBD5E1);

  static const double recipientSizeMax = 38;
  static const double recipientSizeMin = 22;

  /// Main certificate headings (PARTICIPATION, WINNER, RUNNER-UP, CERTIFICATE OF).
  static pw.TextStyle headingMain(CertificateFonts fonts, {double size = 30}) => pw.TextStyle(
        font: fonts.headingBold,
        fontSize: size,
        letterSpacing: 1.2,
        color: navy,
      );

  /// Achievement subheadings (FIRST PLACE, SECOND PLACE).
  static pw.TextStyle achievementSubhead(CertificateVisualVariant variant, CertificateFonts fonts) =>
      pw.TextStyle(
        font: fonts.headingSemiBold,
        fontSize: 16,
        letterSpacing: 2.4,
        color: variant.accent,
      );

  static pw.TextStyle bodyRegular(CertificateFonts fonts, {double size = 11}) => pw.TextStyle(
        font: fonts.bodyRegular,
        fontSize: size,
        color: muted,
        lineSpacing: 1.45,
      );

  static pw.TextStyle bodyMedium(CertificateFonts fonts, {double size = 10}) => pw.TextStyle(
        font: fonts.bodyMedium,
        fontSize: size,
        color: muted,
        lineSpacing: 1.4,
      );

  static pw.TextStyle bodySemiBold(CertificateFonts fonts, {double size = 11}) => pw.TextStyle(
        font: fonts.bodySemiBold,
        fontSize: size,
        color: ink,
        lineSpacing: 1.45,
      );

  static pw.TextStyle bodyBold(CertificateFonts fonts, {double size = 11}) => pw.TextStyle(
        font: fonts.bodyBold,
        fontSize: size,
        color: ink,
        lineSpacing: 1.45,
      );

  static pw.TextStyle recipientScript(CertificateFonts fonts, double size) => pw.TextStyle(
        font: fonts.recipientScript,
        fontSize: size,
        color: navy,
      );

  static pw.TextStyle orgHeader(CertificateFonts fonts) => pw.TextStyle(
        font: fonts.bodyMedium,
        fontSize: 9.5,
        color: navy,
        letterSpacing: 0.3,
      );

  static pw.TextStyle signatoryName(CertificateFonts fonts) => pw.TextStyle(
        font: fonts.bodySemiBold,
        fontSize: 9,
        color: ink,
      );

  static pw.TextStyle signatoryTitle(CertificateFonts fonts) => pw.TextStyle(
        font: fonts.bodyRegular,
        fontSize: 8,
        color: muted,
      );

  static pw.TextStyle footerTagline(CertificateFonts fonts) => pw.TextStyle(
        font: fonts.bodyMedium,
        fontSize: 7.5,
        letterSpacing: 1.8,
        color: muted,
      );

  static double recipientFontSize(String name) {
    final int len = name.trim().length;
    if (len <= 22) return recipientSizeMax;
    if (len <= 32) return 34;
    if (len <= 44) return 30;
    if (len <= 56) return 26;
    return recipientSizeMin;
  }

  static double bodyFontSize(String combined) {
    final int len = combined.length;
    if (len <= 180) return 11;
    if (len <= 260) return 10;
    return 9.5;
  }

  static double submissionFontSize(String title) {
    final int len = title.trim().length;
    if (len <= 48) return 11;
    if (len <= 72) return 10;
    return 9;
  }
}
