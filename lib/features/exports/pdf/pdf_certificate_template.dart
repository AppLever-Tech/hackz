import 'package:pdf/widgets.dart' as pw;

import '../models/export_exception.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';
import 'pdf_engine.dart';
import 'pdf_export_context.dart';
import 'pdf_theme.dart';

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
    final pw.Document document = pw.Document(
      title: context.documentTitle,
      author: 'Hackz',
      creator: 'Hackz',
      subject: '${context.organisationName} ${request.module.displayName}',
    );
    for (final Map<String, Object?> row in table.rows) {
      document.addPage(
        pw.Page(
          pageFormat: PdfTheme.certificatePageFormat,
          margin: PdfTheme.certificateMargin,
          build: (_) => PdfEngine.certificatePage(context: context, row: row),
        ),
      );
    }
    return document.save();
  }
}
