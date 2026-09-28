import '../certificate/certificate_document_builder.dart';
import '../models/export_exception.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';
import 'pdf_export_context.dart';

/// Presentation-oriented certificate layout. Reports use [PdfReportTemplate].
abstract final class PdfCertificateTemplate {
  static Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
    required PdfExportContext context,
  }) async {
    if (table.isEmpty) {
      throw ExportException.noData();
    }
    return CertificateDocumentBuilder.render(
      table: table,
      request: request,
      context: context,
    );
  }
}
