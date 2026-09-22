import 'package:pdf/widgets.dart' as pw;

import '../models/export_request.dart';
import '../models/export_table.dart';
import '../pdf/pdf_export_context.dart';
import '../pdf/pdf_theme.dart';
import 'certificate_data.dart';
import 'certificate_data_mapper.dart';
import 'certificate_pdf_assets.dart';
import 'certificate_sample_a_render_context.dart';
import 'certificate_sample_a_renderer.dart';
import 'certificate_type.dart';

/// Builds certificate PDF bytes through the Sample A renderer.
abstract final class CertificateDocumentBuilder {
  CertificateDocumentBuilder._();

  static Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
    required PdfExportContext context,
  }) async {
    final pw.MemoryImage? hackzLogo = await CertificatePdfAssets.loadHackzLogo();
    final CertificateSampleARenderContext renderContext = await CertificateSampleARenderContext.load();
    final pw.Document document = pw.Document(
      title: context.documentTitle,
      author: 'Hackz',
      creator: 'Hackz',
      subject: '${context.organisationName} ${request.module.displayName}',
    );

    for (final Map<String, Object?> row in table.rows) {
      final CertificateData data = CertificateDataMapper.fromExportRow(
        row: row,
        request: request,
        context: context,
        hackzLogo: hackzLogo,
      );
      document.addPage(
        pw.Page(
          pageFormat: PdfTheme.certificatePageFormat,
          margin: _pageMargin(data, renderContext),
          build: (_) => CertificateSampleARenderer.buildPage(data: data, context: renderContext),
        ),
      );
    }
    return document.save();
  }

  /// Test / preview helper without export table wiring.
  static Future<List<int>> renderCertificates(List<CertificateData> certificates) async {
    final pw.MemoryImage? hackzLogo = await CertificatePdfAssets.loadHackzLogo();
    final CertificateSampleARenderContext renderContext = await CertificateSampleARenderContext.load();
    final pw.Document document = pw.Document(
      title: 'Certificates',
      author: 'Hackz',
      creator: 'Hackz',
    );
    for (final CertificateData raw in certificates) {
      final CertificateData data = CertificateData(
        certificateType: raw.certificateType,
        recipientType: raw.recipientType,
        recipientName: raw.recipientName,
        teamName: raw.teamName,
        organisationName: raw.organisationName,
        organisationLogo: raw.organisationLogo,
        hackzLogo: hackzLogo ?? raw.hackzLogo,
        eventName: raw.eventName,
        eventTemplateLabel: raw.eventTemplateLabel,
        eventDateLabel: raw.eventDateLabel,
        submissionTitle: raw.submissionTitle,
        submissionLabel: raw.submissionLabel,
        achievementLabel: raw.achievementLabel,
        signatories: raw.signatories,
      );
      document.addPage(
        pw.Page(
          pageFormat: PdfTheme.certificatePageFormat,
          margin: _pageMargin(data, renderContext),
          build: (_) => CertificateSampleARenderer.buildPage(data: data, context: renderContext),
        ),
      );
    }
    return document.save();
  }

  static pw.EdgeInsets _pageMargin(CertificateData data, CertificateSampleARenderContext renderContext) {
    if (data.certificateType == CertificateType.participation &&
        renderContext.participationBackground != null) {
      return pw.EdgeInsets.zero;
    }
    return PdfTheme.certificateMargin;
  }
}
