import 'package:pdf/widgets.dart' as pw;

import '../models/export_table.dart';
import 'pdf_export_context.dart';
import 'pdf_theme.dart';

/// Reusable PDF building blocks shared by report and certificate templates.
abstract final class PdfEngine {
  static pw.Widget header(PdfExportContext context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Container(height: 3, color: PdfTheme.brand),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text('HACKZ', style: PdfTheme.brandMark),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    context.organisationName,
                    style: PdfTheme.caption,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: <pw.Widget>[
                  pw.Text(
                    context.documentTitle,
                    style: PdfTheme.headerTitle,
                    textAlign: pw.TextAlign.right,
                    maxLines: 2,
                  ),
                  if (context.hasEvent) ...<pw.Widget>[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      context.eventName,
                      style: PdfTheme.caption,
                      textAlign: pw.TextAlign.right,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 0.8, color: PdfTheme.line),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static pw.Widget footer(PdfExportContext context, pw.Context page) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.SizedBox(height: 6),
        pw.Container(height: 0.8, color: PdfTheme.line),
        pw.SizedBox(height: 6),
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Text(
                'Generated ${context.generatedAtLabel}',
                style: PdfTheme.footer,
              ),
            ),
            pw.Text(
              'Page ${page.pageNumber} of ${page.pagesCount}',
              style: PdfTheme.footer,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget sectionTitle(String title) {
    final String label = title.trim();
    if (label.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 4),
      child: pw.Text(label, style: PdfTheme.section),
    );
  }

  static pw.Widget bodyText(String text) {
    final String value = text.trim();
    if (value.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Text(value, style: PdfTheme.body),
    );
  }

  static pw.Widget metaSection(List<(String, String)> pairs) {
    final List<(String, String)> visible = pairs
        .where(
          ((String, String) pair) =>
              pair.$1.trim().isNotEmpty && pair.$2.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (visible.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: pw.BoxDecoration(
          color: PdfTheme.zebra,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfTheme.line, width: 0.6),
        ),
        child: pw.Wrap(
          spacing: 24,
          runSpacing: 8,
          children: visible
              .map(
                ((String, String) pair) => pw.ConstrainedBox(
                  constraints: const pw.BoxConstraints(
                    minWidth: 160,
                    maxWidth: 280,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text(pair.$1, style: PdfTheme.metaLabel),
                      pw.SizedBox(height: 2),
                      pw.Text(pair.$2, style: PdfTheme.metaValue, maxLines: 3),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  static pw.Widget table(ExportTable table) {
    final List<String> headers = table.columns
        .map((ExportColumn column) => column.header)
        .toList(growable: false);
    final List<List<String>> data = table.rows
        .map(
          (Map<String, Object?> row) => table.columns
              .map((ExportColumn column) => formatValue(row[column.key]))
              .toList(growable: false),
        )
        .toList(growable: false);
    final Map<int, pw.AlignmentGeometry> alignments =
        <int, pw.AlignmentGeometry>{
          for (int i = 0; i < table.columns.length; i++)
            i: _isNumericColumn(table, table.columns[i])
                ? pw.Alignment.centerRight
                : pw.Alignment.centerLeft,
        };
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: PdfTheme.tableHeader,
      cellStyle: PdfTheme.tableCell,
      headerAlignment: pw.Alignment.centerLeft,
      headerAlignments: alignments,
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: alignments,
      headerDecoration: const pw.BoxDecoration(color: PdfTheme.headerFill),
      oddRowDecoration: const pw.BoxDecoration(color: PdfTheme.zebra),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      border: pw.TableBorder.all(color: PdfTheme.line, width: 0.5),
      columnWidths: <int, pw.TableColumnWidth>{
        for (int i = 0; i < table.columns.length; i++)
          i: pw.FlexColumnWidth(_columnFlex(table.columns[i])),
      },
      tableWidth: pw.TableWidth.max,
    );
  }

  static String formatValue(Object? value) {
    if (value == null) return '';
    if (value is int) return '$value';
    if (value is double) {
      if (value == value.roundToDouble()) return '${value.toInt()}';
      return value.toString();
    }
    if (value is num) return value.toString();
    return '$value'.trim();
  }

  static bool _isNumericColumn(ExportTable table, ExportColumn column) {
    for (final Map<String, Object?> row in table.rows) {
      final Object? value = row[column.key];
      if (value == null) continue;
      return value is num;
    }
    return false;
  }

  static double _columnFlex(ExportColumn column) {
    final String key = column.key.toLowerCase();
    final String header = column.header.toLowerCase();
    if (key.contains('title') ||
        header.contains('title') ||
        key == 'idea' ||
        key == 'problem') {
      return 2.2;
    }
    if (key.contains('remarks') || header.contains('remark')) return 1.6;
    if (key == 'number' ||
        key.contains('status') ||
        key == 'amount' ||
        key == 'proof') {
      return 0.8;
    }
    return 1;
  }
}
