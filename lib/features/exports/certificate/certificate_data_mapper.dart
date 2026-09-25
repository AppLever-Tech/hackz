import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../models/export_module.dart';
import '../models/export_request.dart';
import '../pdf/pdf_engine.dart';
import '../pdf/pdf_export_context.dart';
import 'certificate_data.dart';
import 'certificate_pdf_assets.dart';
import 'certificate_type.dart';

/// Maps export rows + request context to [CertificateData] (no event-specific logic).
abstract final class CertificateDataMapper {
  CertificateDataMapper._();

  static CertificateData fromExportRow({
    required Map<String, Object?> row,
    required ExportRequest request,
    required PdfExportContext context,
    pw.ImageProvider? hackzLogo,
    pw.ImageProvider? organisationLogoFallback,
  }) {
    final CertificateType type = _resolveType(row, request.module);
    final CertificateRecipientType recipientType =
        CertificateRecipientTypeCodec.parse(PdfEngine.formatValue(row['recipientType']));
    final List<CertificateSignatory> signatories = _signatoriesFromRow(row);

    return CertificateData(
      certificateType: type,
      recipientType: recipientType,
      recipientName: PdfEngine.formatValue(row['recipient']),
      teamName: PdfEngine.formatValue(row['team']),
      organisationName: context.organisationName,
      organisationLogo: CertificatePdfAssets.memoryImage(row['organisationLogoBytes'] as List<int>?) ??
          organisationLogoFallback,
      hackzLogo: hackzLogo,
      eventName: context.eventName,
      eventTemplateLabel: PdfEngine.formatValue(row['eventType']),
      eventDateLabel: PdfEngine.formatValue(row['eventDates']),
      submissionTitle: PdfEngine.formatValue(row['entry']),
      submissionLabel: PdfEngine.formatValue(row['submissionLabel']),
      achievementLabel: PdfEngine.formatValue(row['achievementLabel']),
      signatories: signatories,
    );
  }

  static CertificateType _resolveType(Map<String, Object?> row, ExportModule module) {
    final CertificateType? parsed =
        CertificateTypeCodec.parse(PdfEngine.formatValue(row['certificateType']));
    if (parsed != null) return parsed;
    if (module == ExportModule.participationCertificate) {
      return CertificateType.participation;
    }
    final String place = PdfEngine.formatValue(row['place']).toLowerCase();
    if (place.contains('runner')) return CertificateType.runnerUp;
    return CertificateType.winner;
  }

  static List<CertificateSignatory> _signatoriesFromRow(Map<String, Object?> row) {
    final List<CertificateSignatory> parsed = <CertificateSignatory>[
      _signatory(row, 1),
      _signatory(row, 2),
    ].where((CertificateSignatory s) => s.name.isNotEmpty || s.designation.isNotEmpty).toList();
    return parsed;
  }

  static CertificateSignatory _signatory(Map<String, Object?> row, int index) {
    final String name = PdfEngine.formatValue(row['signatory${index}Name']);
    final String designation = PdfEngine.formatValue(row['signatory${index}Designation']);
    final List<int>? raw = row['signatory${index}SignatureBytes'] as List<int>?;
    final pw.MemoryImage? image = raw == null || raw.isEmpty
        ? null
        : CertificatePdfAssets.memoryImageForCertificateEmbed(Uint8List.fromList(raw));
    return CertificateSignatory(name: name, designation: designation, signatureImage: image);
  }
}
