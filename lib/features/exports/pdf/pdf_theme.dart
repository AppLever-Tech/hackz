import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Hackz visual tokens for PDF output. Mirrors app brand colors, not a design engine.
abstract final class PdfTheme {
  static const PdfColor brand = PdfColor.fromInt(0xFF6A38FF);
  static const PdfColor ink = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor muted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor line = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor headerFill = PdfColor.fromInt(0xFFF5F3FF);
  static const PdfColor zebra = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);

  static final PdfPageFormat reportPageFormat = PdfPageFormat.a4.landscape;
  static const PdfPageFormat certificatePageFormat = PdfPageFormat.a4;

  static const pw.EdgeInsets reportMargin = pw.EdgeInsets.fromLTRB(
    28,
    22,
    28,
    22,
  );
  static const pw.EdgeInsets certificateMargin = pw.EdgeInsets.fromLTRB(
    36,
    36,
    36,
    36,
  );

  static const int reportMaxPages = 200;

  static pw.TextStyle get brandMark => pw.TextStyle(
    font: pw.Font.helveticaBold(),
    fontSize: 11,
    letterSpacing: 1.4,
    color: brand,
  );

  static pw.TextStyle get headerTitle =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 11, color: ink);

  static pw.TextStyle get title =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 16, color: ink);

  static pw.TextStyle get section =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 10.5, color: ink);

  static pw.TextStyle get body => pw.TextStyle(
    font: pw.Font.helvetica(),
    fontSize: 9,
    color: ink,
    lineSpacing: 1.3,
  );

  static pw.TextStyle get caption =>
      pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8, color: muted);

  static pw.TextStyle get metaLabel =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8, color: muted);

  static pw.TextStyle get metaValue =>
      pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: ink);

  static pw.TextStyle get tableHeader =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 8, color: ink);

  static pw.TextStyle get tableCell =>
      pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8, color: ink);

  static pw.TextStyle get footer =>
      pw.TextStyle(font: pw.Font.helvetica(), fontSize: 8, color: muted);

  static pw.TextStyle get certificateKicker => pw.TextStyle(
    font: pw.Font.helvetica(),
    fontSize: 10,
    letterSpacing: 1.6,
    color: muted,
  );

  static pw.TextStyle get certificateTitle =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 22, color: ink);

  static pw.TextStyle get certificateBody => pw.TextStyle(
    font: pw.Font.helvetica(),
    fontSize: 12,
    color: muted,
    lineSpacing: 1.4,
  );

  static pw.TextStyle get certificateRecipient =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 22, color: brand);

  static pw.TextStyle get certificateEvent =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 14, color: ink);

  static pw.TextStyle get certificatePlace =>
      pw.TextStyle(font: pw.Font.helveticaBold(), fontSize: 13, color: brand);

  static pw.TextStyle get signatureLabel =>
      pw.TextStyle(font: pw.Font.helvetica(), fontSize: 9, color: muted);
}
