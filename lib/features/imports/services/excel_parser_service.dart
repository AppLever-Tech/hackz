import 'package:excel/excel.dart';

import '../constants/import_constants.dart';
import '../sources/problem_normalized_row_mapper.dart';
import '../sources/problem_source_extract_exception.dart';
import 'csv_parser_service.dart';
import 'xls_sheet_parser.dart';

/// One worksheet from an uploaded Excel workbook.
class ExcelSheetTable {
  const ExcelSheetTable({required this.name, required this.matrix});

  final String name;
  final List<List<String>> matrix;

  bool get hasData => matrix.any((List<String> row) => row.any((String cell) => cell.trim().isNotEmpty));
}

/// Reads `.xlsx` / `.xls` into string matrices for the shared Problem Import pipeline.
abstract final class ExcelParserService {
  ExcelParserService._();

  static Future<List<ExcelSheetTable>> parseBytes(List<int> bytes) async {
    if (bytes.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.invalidExcelFileMessage);
    }

    final Excel workbook;
    try {
      if (_isOleCompound(bytes)) {
        return XlsSheetParser.parse(bytes)
            .map((XlsParsedSheet sheet) => ExcelSheetTable(name: sheet.name, matrix: sheet.matrix))
            .where((ExcelSheetTable sheet) => sheet.hasData)
            .toList(growable: false);
      }
      workbook = Excel.decodeBytes(List<int>.from(bytes));
    } on ProblemSourceExtractException {
      rethrow;
    } catch (e) {
      throw ProblemSourceExtractException('${ImportConstants.invalidExcelFileMessage} $e');
    }

    final List<ExcelSheetTable> sheets = <ExcelSheetTable>[];
    for (final String name in workbook.tables.keys) {
      final Sheet? sheet = workbook.tables[name];
      if (sheet == null) continue;
      final ExcelSheetTable table = ExcelSheetTable(name: name, matrix: _matrixFrom(sheet));
      if (table.hasData) sheets.add(table);
    }
    return sheets;
  }

  static List<ExcelSheetTable> usableSheets(List<ExcelSheetTable> sheets) =>
      sheets.where((ExcelSheetTable sheet) => sheet.hasData).toList(growable: false);

  /// Builds an `.xlsx` workbook from the same header + example rows as [csv].
  static List<int> workbookBytesFromCsv(String csv, {String sheetName = 'Problems'}) {
    final List<List<String>> matrix = CsvParserService.parseMatrix(csv);
    if (matrix.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.emptyExcelFileMessage);
    }

    final Excel book = Excel.createExcel();
    final String defaultName = book.getDefaultSheet() ?? 'Sheet1';
    if (defaultName != sheetName) {
      book.rename(defaultName, sheetName);
    }
    final Sheet sheet = book[sheetName];
    for (final List<String> row in matrix) {
      sheet.appendRow(row.map(TextCellValue.new).toList(growable: false));
    }

    final List<int>? bytes = book.encode();
    if (bytes == null || bytes.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.invalidExcelFileMessage);
    }
    return bytes;
  }

  static List<Map<String, String>> rowsFromSheet(ExcelSheetTable sheet) {
    List<Map<String, String>> rows = ProblemNormalizedRowMapper.rowsFromFirstHeaderRow(sheet.matrix);
    if (rows.isEmpty) {
      rows = ProblemNormalizedRowMapper.rowsFromDetectedHeaders(sheet.matrix);
    }
    return rows;
  }

  static bool _isOleCompound(List<int> bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0 &&
        bytes[4] == 0xA1 &&
        bytes[5] == 0xB1 &&
        bytes[6] == 0x1A &&
        bytes[7] == 0xE1;
  }

  static List<List<String>> _matrixFrom(Sheet sheet) {
    final List<List<String>> matrix = <List<String>>[];
    for (final List<Data?> row in sheet.rows) {
      final List<String> cells = row.map(_cellText).toList(growable: false);
      if (cells.every((String cell) => cell.isEmpty)) continue;
      matrix.add(cells);
    }
    return matrix;
  }

  static String _cellText(Data? cell) {
    if (cell == null) return '';
    return _stringify(cell.value);
  }

  static String _stringify(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.toString().trim();
    if (value is IntCellValue) return '${value.value}';
    if (value is DoubleCellValue) {
      final double n = value.value;
      return n == n.roundToDouble() ? '${n.toInt()}' : '$n';
    }
    if (value is BoolCellValue) return value.value ? 'true' : 'false';
    if (value is DateCellValue) {
      final String y = value.year.toString().padLeft(4, '0');
      final String m = value.month.toString().padLeft(2, '0');
      final String d = value.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    if (value is DateTimeCellValue) {
      final String y = value.year.toString().padLeft(4, '0');
      final String m = value.month.toString().padLeft(2, '0');
      final String d = value.day.toString().padLeft(2, '0');
      final String hh = value.hour.toString().padLeft(2, '0');
      final String mm = value.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $hh:$mm';
    }
    if (value is TimeCellValue) {
      final String hh = value.hour.toString().padLeft(2, '0');
      final String mm = value.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    if (value is FormulaCellValue) return value.formula.trim();
    return value.toString().trim();
  }
}
