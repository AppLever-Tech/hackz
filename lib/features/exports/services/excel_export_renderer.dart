import 'package:excel/excel.dart';

import '../models/export_exception.dart';
import '../models/export_format.dart';
import '../models/export_request.dart';
import '../models/export_table.dart';
import 'export_renderer.dart';

class ExcelExportRenderer implements ExportRenderer {
  const ExcelExportRenderer();

  @override
  ExportFormat get format => ExportFormat.excel;

  @override
  Future<List<int>> render({
    required ExportTable table,
    required ExportRequest request,
  }) async {
    final Excel book = Excel.createExcel();
    final String sheetName = _sheetName(table.sheetName);
    final String defaultName = book.getDefaultSheet() ?? 'Sheet1';
    if (defaultName != sheetName) {
      book.rename(defaultName, sheetName);
    }
    final Sheet sheet = book[sheetName];
    sheet.appendRow(
      table.columns.map((ExportColumn column) => TextCellValue(column.header)).toList(growable: false),
    );
    for (final Map<String, String> row in table.rows) {
      sheet.appendRow(
        table.columns
            .map((ExportColumn column) => TextCellValue(row[column.key] ?? ''))
            .toList(growable: false),
      );
    }
    final List<int>? bytes = book.encode();
    if (bytes == null || bytes.isEmpty) {
      throw ExportException.generationFailed('Excel encoding returned an empty file.');
    }
    return bytes;
  }

  static String _sheetName(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Export';
    return trimmed.length <= 31 ? trimmed : trimmed.substring(0, 31);
  }
}
