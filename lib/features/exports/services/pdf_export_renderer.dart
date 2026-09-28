import '../models/export_format.dart';
import '../models/export_module.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';
import '../pdf/pdf_certificate_template.dart';
import '../pdf/pdf_export_context.dart';
import '../pdf/pdf_report_template.dart';
import 'export_renderer.dart';

/// `ExportTable → PDF template → bytes`. Templates share one PDF engine.
class PdfExportRenderer implements ExportRenderer {
  const PdfExportRenderer();

  @override
  ExportFormat get format => ExportFormat.pdf;

  @override
  Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
  }) async {
    final PdfExportContext context = PdfExportContext.resolve(
      request: request,
      table: table,
    );
    switch (request.module.documentKind) {
      case ExportDocumentKind.report:
        return PdfReportTemplate.render(
          table: table,
          request: request,
          context: context,
        );
      case ExportDocumentKind.certificate:
        return PdfCertificateTemplate.render(
          table: table,
          request: request,
          context: context,
        );
    }
  }
}
