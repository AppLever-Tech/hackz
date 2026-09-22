import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'certificate_type.dart';

/// Sample A visual tokens (landscape premium certificate).
abstract final class CertificateSampleATheme {
  static const PdfColor navy = PdfColor.fromInt(0xFF0B1F3A);
  static const PdfColor navySoft = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor ink = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor muted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor line = PdfColor.fromInt(0xFFDCE3EE);
  static const PdfColor gold = PdfColor.fromInt(0xFFC9A227);
  static const PdfColor goldBright = PdfColor.fromInt(0xFFD4AF37);
  static const PdfColor silver = PdfColor.fromInt(0xFF94A3B8);
  static const PdfColor runnerBlue = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);

  static CertificatePalette palette(CertificateType type) => switch (type) {
        CertificateType.participation => const CertificatePalette(
              accent: gold,
              accentSoft: PdfColor.fromInt(0xFFF5E6B8),
              headline: navy,
            ),
        CertificateType.winner => const CertificatePalette(
              accent: goldBright,
              accentSoft: PdfColor.fromInt(0xFFF7E7A3),
              headline: navy,
            ),
        CertificateType.runnerUp => const CertificatePalette(
              accent: runnerBlue,
              accentSoft: PdfColor.fromInt(0xFFE0EAFF),
              headline: navySoft,
            ),
      };

  static pw.TextStyle get orgName => pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 11,
        color: navy,
        letterSpacing: 0.2,
      );

  static pw.TextStyle headlinePrimary(CertificatePalette palette) => pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 26,
        letterSpacing: 2.4,
        color: palette.headline,
      );

  static pw.TextStyle headlineSecondary(CertificatePalette palette) => pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 18,
        letterSpacing: 1.8,
        color: palette.accent,
      );

  static pw.TextStyle get body => pw.TextStyle(
        font: pw.Font.helvetica(),
        fontSize: 11.5,
        color: muted,
        lineSpacing: 1.35,
      );

  static pw.TextStyle get recipient => pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 24,
        color: navy,
        letterSpacing: 0.3,
      );

  static pw.TextStyle get eventTitle => pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 14,
        color: ink,
      );

  static pw.TextStyle get submission => pw.TextStyle(
        font: pw.Font.helvetica(),
        fontSize: 12,
        color: ink,
      );

  static pw.TextStyle get signatoryName => pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 9.5,
        color: ink,
      );

  static pw.TextStyle get signatoryTitle => pw.TextStyle(
        font: pw.Font.helvetica(),
        fontSize: 8.5,
        color: muted,
      );

  static pw.TextStyle get footerBrand => pw.TextStyle(
        font: pw.Font.helvetica(),
        fontSize: 7.5,
        letterSpacing: 1.2,
        color: muted,
      );
}

class CertificatePalette {
  const CertificatePalette({
    required this.accent,
    required this.accentSoft,
    required this.headline,
  });

  final PdfColor accent;
  final PdfColor accentSoft;
  final PdfColor headline;
}
