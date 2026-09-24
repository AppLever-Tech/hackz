import 'package:pdf/widgets.dart' as pw;

import '../models/export_request.dart';
import '../models/export_table.dart';
import '../pdf/pdf_export_context.dart';
import '../pdf/pdf_theme.dart';
import 'certificate_data.dart';
import 'certificate_data_mapper.dart';
import 'certificate_organisation_logo_loader.dart';
import 'certificate_pdf_assets.dart';
import 'certificate_render_context.dart';
import 'certificate_renderer.dart';

/// Builds certificate PDF bytes through the certificate renderer.
abstract final class CertificateDocumentBuilder {
  CertificateDocumentBuilder._();

  static Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
    required PdfExportContext context,
  }) async {
    final pw.MemoryImage? hackzLogo = await CertificatePdfAssets.loadHackzLogo();
    final CertificateRenderContext renderContext = await CertificateRenderContext.load();
    final pw.ImageProvider? organisationLogo =
        await CertificateOrganisationLogoLoader.loadForOrg(request.actor.orgId);
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
        organisationLogoFallback: organisationLogo,
      );
      document.addPage(
        pw.Page(
          pageFormat: PdfTheme.certificatePageFormat,
          margin: _pageMargin(data, renderContext),
          build: (_) => CertificateRenderer.buildPage(data: data, context: renderContext),
        ),
      );
    }
    return document.save();
  }

  /// Test / preview helper without export table wiring.
  static Future<List<int>> renderCertificates(List<CertificateData> certificates) async {
    final pw.MemoryImage? hackzLogo = await CertificatePdfAssets.loadHackzLogo();
    final CertificateRenderContext renderContext = await CertificateRenderContext.load();
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
          build: (_) => CertificateRenderer.buildPage(data: data, context: renderContext),
        ),
      );
    }
    return document.save();
  }

  static pw.EdgeInsets _pageMargin(CertificateData data, CertificateRenderContext renderContext) {
    if (renderContext.participationBackground != null) {
      return pw.EdgeInsets.zero;
    }
    return PdfTheme.certificateMargin;
  }
}
