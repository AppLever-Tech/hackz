import 'package:archive/archive.dart';

import '../services/export_file_namer.dart';
import 'certificate_data.dart';
import 'certificate_document_builder.dart';
import 'certificate_generation_plan.dart';
import 'certificate_type.dart';

class CertificateGenerationProgress {
  const CertificateGenerationProgress({
    required this.phase,
    required this.completed,
    required this.total,
    this.failed = 0,
  });

  final String phase;
  final int completed;
  final int total;
  final int failed;
}

class CertificateGenerationResult {
  const CertificateGenerationResult({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    required this.succeeded,
    required this.failed,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final int succeeded;
  final int failed;
}

typedef CertificateProgressCallback = void Function(CertificateGenerationProgress progress);

/// Bounded certificate rendering (single PDF, multi-page PDF, or ZIP).
abstract final class CertificateBatchGenerator {
  CertificateBatchGenerator._();

  static const String pdfMime = 'application/pdf';
  static const String zipMime = 'application/zip';

  static Future<CertificateGenerationResult> generate({
    required List<CertificateData> certificates,
    required CertificateGenerationPlan plan,
    required String eventName,
    CertificateProgressCallback? onProgress,
  }) async {
    if (certificates.isEmpty) {
      throw StateError('No certificates to generate.');
    }
    onProgress?.call(
      CertificateGenerationProgress(phase: 'Preparing', completed: 0, total: certificates.length),
    );

    switch (plan.outputMode) {
      case CertificateOutputMode.singlePdf:
      case CertificateOutputMode.multiPagePdf:
        return _generateCombinedPdf(
          certificates: certificates,
          plan: plan,
          eventName: eventName,
          onProgress: onProgress,
        );
      case CertificateOutputMode.zipArchive:
        return _generateZip(
          certificates: certificates,
          plan: plan,
          eventName: eventName,
          onProgress: onProgress,
        );
    }
  }

  static Future<CertificateGenerationResult> _generateCombinedPdf({
    required List<CertificateData> certificates,
    required CertificateGenerationPlan plan,
    required String eventName,
    CertificateProgressCallback? onProgress,
  }) async {
    const int failed = 0;
    onProgress?.call(
      CertificateGenerationProgress(
        phase: 'Processing',
        completed: certificates.length,
        total: certificates.length,
        failed: failed,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(certificates);
    onProgress?.call(
      CertificateGenerationProgress(
        phase: 'Completed',
        completed: certificates.length,
        total: certificates.length,
        failed: failed,
      ),
    );
    return CertificateGenerationResult(
      bytes: bytes,
      fileName: _pdfFileName(
        eventName: eventName,
        plan: plan,
        singleRecipient: certificates.length == 1 ? certificates.first.recipientName : '',
      ),
      mimeType: pdfMime,
      succeeded: certificates.length,
      failed: failed,
    );
  }

  static Future<CertificateGenerationResult> _generateZip({
    required List<CertificateData> certificates,
    required CertificateGenerationPlan plan,
    required String eventName,
    CertificateProgressCallback? onProgress,
  }) async {
    final Archive archive = Archive();
    int succeeded = 0;
    int failed = 0;
    for (int i = 0; i < certificates.length; i++) {
      final CertificateData data = certificates[i];
      try {
        final List<int> pdf = await CertificateDocumentBuilder.renderCertificates(<CertificateData>[data]);
        final String name = _zipEntryName(data, i);
        archive.addFile(ArchiveFile(name, pdf.length, pdf));
        succeeded++;
      } catch (_) {
        failed++;
      }
      if (i % CertificateBatchPolicy.renderChunkSize == CertificateBatchPolicy.renderChunkSize - 1 ||
          i == certificates.length - 1) {
        onProgress?.call(
          CertificateGenerationProgress(
            phase: 'Processing',
            completed: i + 1,
            total: certificates.length,
            failed: failed,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      }
    }
    final List<int>? zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null || zipBytes.isEmpty) {
      throw StateError('Unable to build certificate archive.');
    }
    onProgress?.call(
      CertificateGenerationProgress(
        phase: 'Completed',
        completed: certificates.length,
        total: certificates.length,
        failed: failed,
      ),
    );
    return CertificateGenerationResult(
      bytes: zipBytes,
      fileName: _zipFileName(eventName: eventName, plan: plan),
      mimeType: zipMime,
      succeeded: succeeded,
      failed: failed,
    );
  }

  static String _zipEntryName(CertificateData data, int index) {
    final String recipient = ExportFileNamer.sanitize(data.recipientName);
    final String suffix = (index + 1).toString().padLeft(4, '0');
    if (recipient.isEmpty) return 'certificate_$suffix.pdf';
    return '${recipient}_$suffix.pdf';
  }

  static String _pdfFileName({
    required String eventName,
    required CertificateGenerationPlan plan,
    required String singleRecipient,
  }) {
    final String token = switch (plan.certificateType) {
      CertificateType.participation => 'ParticipationCertificate',
      CertificateType.winner => 'WinnerCertificate',
      CertificateType.runnerUp => 'RunnerUpCertificate',
    };
    final List<String> parts = <String>['Hackz', ExportFileNamer.sanitize(eventName), token];
    if (singleRecipient.trim().isNotEmpty) {
      parts.add(ExportFileNamer.sanitize(singleRecipient));
    }
    parts.add(_dateStamp(DateTime.now()));
    return '${parts.join('_')}.pdf';
  }

  static String _zipFileName({
    required String eventName,
    required CertificateGenerationPlan plan,
  }) {
    final String token = switch (plan.certificateType) {
      CertificateType.participation => 'ParticipationCertificates',
      CertificateType.winner => 'WinnerCertificates',
      CertificateType.runnerUp => 'RunnerUpCertificates',
    };
    final List<String> parts = <String>['Hackz', ExportFileNamer.sanitize(eventName), token, _dateStamp(DateTime.now())];
    return '${parts.join('_')}.zip';
  }

  static String _dateStamp(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
