import '../models/export_exception.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';
import 'pdf_export_context.dart';

/// Presentation-oriented certificate layout.
///
/// Shares [PdfTheme] / [PdfEngine] with reports. Not implemented in Phase 3;
/// later certificates can use college/event branding, recipient, achievement,
/// event details, date, reference id, and signatures without changing the engine.
abstract final class PdfCertificateTemplate {
  static Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
    required PdfExportContext context,
  }) async {
    throw ExportException.unsupportedFormat();
  }
}
