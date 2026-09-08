import '../models/export_exception.dart';
import '../models/export_format.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';
import 'export_renderer.dart';

/// Placeholder so PDF templates can plug in later without changing providers.
///
/// Future: `ExportTable → PDF generator → PDF template → bytes`.
class PdfExportRenderer implements ExportRenderer {
  const PdfExportRenderer();

  @override
  ExportFormat get format => ExportFormat.pdf;

  @override
  Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
  }) async {
    throw ExportException.unsupportedFormat();
  }
}
