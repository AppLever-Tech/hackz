import 'dart:convert';

/// Shared CSV parsing for all Hackz import types.
abstract final class CsvParserService {
  static List<Map<String, String>> parse(String raw) {
    final List<List<String>> matrix = parseMatrix(raw);
    if (matrix.isEmpty) return const <Map<String, String>>[];

    final List<String> headers = matrix.first.map(_normalizeHeader).toList(growable: false);
    if (headers.isEmpty) return const <Map<String, String>>[];

    final List<Map<String, String>> rows = <Map<String, String>>[];
    for (var i = 1; i < matrix.length; i++) {
      final List<String> cells = matrix[i];
      final Map<String, String> row = <String, String>{};
      for (var h = 0; h < headers.length; h++) {
        final String key = headers[h];
        if (key.isEmpty) continue;
        row[key] = h < cells.length ? cells[h].trim() : '';
      }
      if (row.values.every((String v) => v.isEmpty)) continue;
      rows.add(row);
    }
    return rows;
  }

  /// Splits CSV text into rows/cells, preserving quoted newlines.
  static List<List<String>> parseMatrix(String raw) {
    String source = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (source.startsWith('\uFEFF')) source = source.substring(1);
    if (source.trim().isEmpty) return const <List<String>>[];

    final List<List<String>> rows = <List<String>>[];
    List<String> currentRow = <String>[];
    final StringBuffer current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < source.length; i++) {
      final String char = source[i];
      if (char == '"') {
        if (inQuotes && i + 1 < source.length && source[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        currentRow.add(current.toString());
        current.clear();
        continue;
      }
      if (char == '\n' && !inQuotes) {
        currentRow.add(current.toString());
        current.clear();
        if (currentRow.any((String cell) => cell.trim().isNotEmpty)) {
          rows.add(currentRow);
        }
        currentRow = <String>[];
        continue;
      }
      current.write(char);
    }

    currentRow.add(current.toString());
    if (currentRow.any((String cell) => cell.trim().isNotEmpty)) {
      rows.add(currentRow);
    }
    return rows;
  }

  static List<Map<String, String>> parseBytes(List<int> bytes) {
    return parse(utf8.decode(bytes));
  }

  /// Reads a cell using the parser's lowercased headers, with a case-insensitive fallback.
  static String cell(Map<String, String> row, String key) {
    final String wanted = key.trim();
    if (wanted.isEmpty) return '';
    final String? direct = row[wanted];
    if (direct != null) return direct.trim();
    final String lower = wanted.toLowerCase();
    final String? lowered = row[lower];
    if (lowered != null) return lowered.trim();
    for (final MapEntry<String, String> entry in row.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value.trim();
    }
    return '';
  }

  static String _normalizeHeader(String raw) => raw.trim().toLowerCase();
}
