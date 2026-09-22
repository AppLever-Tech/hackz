import 'package:pdf/pdf.dart';

import 'certificate_type.dart';

/// Per-type Sample A configuration (shared layout, variant accents only).
class CertificateVisualVariant {
  const CertificateVisualVariant({
    required this.type,
    required this.accent,
    required this.accentLight,
    required this.usesGoldAccents,
    required this.showTrophy,
    required this.showMedal,
    required this.showLaurels,
    required this.closingLine,
  });

  final CertificateType type;
  final PdfColor accent;
  final PdfColor accentLight;
  final bool usesGoldAccents;
  final bool showTrophy;
  final bool showMedal;
  final bool showLaurels;
  final String closingLine;

  static CertificateVisualVariant forType(CertificateType type) => switch (type) {
        CertificateType.participation => const CertificateVisualVariant(
              type: CertificateType.participation,
              accent: PdfColor.fromInt(0xFFC9A227),
              accentLight: PdfColor.fromInt(0xFFD4AF37),
              usesGoldAccents: true,
              showTrophy: false,
              showMedal: false,
              showLaurels: false,
              closingLine: 'IDEAS TODAY · A BRIGHTER TOMORROW',
            ),
        CertificateType.winner => const CertificateVisualVariant(
              type: CertificateType.winner,
              accent: PdfColor.fromInt(0xFFD4AF37),
              accentLight: PdfColor.fromInt(0xFFE8C547),
              usesGoldAccents: true,
              showTrophy: true,
              showMedal: false,
              showLaurels: true,
              closingLine: 'IDEAS TODAY · A BRIGHTER TOMORROW',
            ),
        CertificateType.runnerUp => const CertificateVisualVariant(
              type: CertificateType.runnerUp,
              accent: PdfColor.fromInt(0xFF94A3B8),
              accentLight: PdfColor.fromInt(0xFFCBD5E1),
              usesGoldAccents: false,
              showTrophy: false,
              showMedal: true,
              showLaurels: true,
              closingLine: 'IDEAS TODAY · A BRIGHTER TOMORROW',
            ),
      };
}
