import 'package:pdf/pdf.dart';

import 'certificate_type.dart';

/// Per certificate-type copy and accent tokens (shared layout for all types).
class CertificateVisualVariant {
  const CertificateVisualVariant({
    required this.type,
    required this.accent,
    required this.bodyLeadLine,
    required this.bodyRecognitionLine,
  });

  final CertificateType type;
  final PdfColor accent;
  final String bodyLeadLine;
  final String bodyRecognitionLine;

  static CertificateVisualVariant forType(CertificateType type) => switch (type) {
        CertificateType.participation => const CertificateVisualVariant(
              type: CertificateType.participation,
              accent: PdfColor.fromInt(0xFFC9A227),
              bodyLeadLine: 'for successfully participating in',
              bodyRecognitionLine:
                  'In recognition of their creativity, innovation and contribution to the event.',
            ),
        CertificateType.winner => const CertificateVisualVariant(
              type: CertificateType.winner,
              accent: PdfColor.fromInt(0xFFD4AF37),
              bodyLeadLine: 'for outstanding innovation and exceptional performance in',
              bodyRecognitionLine: 'Your ideas inspire a better tomorrow.',
            ),
        CertificateType.runnerUp => const CertificateVisualVariant(
              type: CertificateType.runnerUp,
              accent: PdfColor.fromInt(0xFF94A3B8),
              bodyLeadLine: 'for commendable innovation and excellent performance in',
              bodyRecognitionLine: 'Well done on turning ideas into impact',
            ),
        CertificateType.thirdPlace => const CertificateVisualVariant(
              type: CertificateType.thirdPlace,
              accent: PdfColor.fromInt(0xFFCD7F32),
              bodyLeadLine: 'for strong innovation and excellent performance in',
              bodyRecognitionLine: 'Well done on turning ideas into impact',
            ),
      };
}
