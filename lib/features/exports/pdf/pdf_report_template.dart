import 'package:pdf/widgets.dart' as pw;

import '../models/export_request.dart';
import '../models/export_table.dart';
import 'pdf_engine.dart';
import 'pdf_export_context.dart';
import 'pdf_theme.dart';

/// Information-oriented PDF layout. Certificates use [PdfCertificateTemplate].
abstract final class PdfReportTemplate {
  static Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
    required PdfExportContext context,
  }) async {
    final pw.Document document = pw.Document(
      title: context.documentTitle,
      author: 'Hackz',
      creator: 'Hackz',
      subject: context.organisationName,
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfTheme.reportPageFormat,
        margin: PdfTheme.reportMargin,
        maxPages: PdfTheme.reportMaxPages,
        header: (_) => PdfEngine.header(context),
        footer: (pw.Context page) => PdfEngine.footer(context, page),
        build: (_) => <pw.Widget>[
          PdfEngine.metaSection(<(String, String)>[
            ('College', context.organisationName),
            ('Organisation code', context.organisationCode),
            if (context.hasEvent) ('Event', context.eventName),
            ('Generated', context.generatedAtLabel),
            ('Records', '${table.rows.length} ${request.module.displayName}'),
          ]),
          PdfEngine.bodyText(
            'This report lists ${request.module.displayName.toLowerCase()} visible in the current workspace filters.',
          ),
          PdfEngine.sectionTitle('Records'),
          PdfEngine.table(table),
        ],
      ),
    );
    return document.save();
  }
}
