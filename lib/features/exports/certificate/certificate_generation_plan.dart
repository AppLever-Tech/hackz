import 'certificate_selectable_entry.dart';
import 'certificate_type.dart';

enum CertificateOutputMode {
  singlePdf,
  multiPagePdf,
  zipArchive,
}

/// Summary shown before confirming generation.
class CertificateGenerationPlan {
  const CertificateGenerationPlan({
    required this.certificateType,
    required this.recipientType,
    required this.selectedEntries,
    required this.estimatedCertificates,
    required this.outputMode,
  });

  final CertificateType certificateType;
  final CertificateRecipientType recipientType;
  final List<CertificateSelectableEntry> selectedEntries;
  final int estimatedCertificates;
  final CertificateOutputMode outputMode;

  int get selectedTeamCount => selectedEntries.length;

  bool get isLargeJob => estimatedCertificates > CertificateBatchPolicy.directPdfMaxCertificates;
}

/// Concurrency and batch thresholds for certificate generation.
abstract final class CertificateBatchPolicy {
  CertificateBatchPolicy._();

  /// Single combined PDF when at or below this count.
  static const int directPdfMaxCertificates = 25;

  /// Certificates rendered per progress tick inside a job.
  static const int renderChunkSize = 6;
}
