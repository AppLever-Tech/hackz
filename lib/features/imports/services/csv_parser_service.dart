import 'dart:convert';

/// Shared CSV parsing for all Hackz import types.
abstract final class CsvParserService {
  static List<Map<String, String>> parse(String raw) {
    final String normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) return const <Map<String, String>>[];

    final List<String> lines = normalized
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) return const <Map<String, String>>[];

    final List<String> headers = _splitLine(lines.first).map(_normalizeHeader).toList(growable: false);
    if (headers.isEmpty) return const <Map<String, String>>[];

    final List<Map<String, String>> rows = <Map<String, String>>[];
    for (var i = 1; i < lines.length; i++) {
      final List<String> cells = _splitLine(lines[i]);
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

  static List<Map<String, String>> parseBytes(List<int> bytes) {
    return parse(utf8.decode(bytes));
  }

  static String _normalizeHeader(String raw) => raw.trim().toLowerCase();

  static List<String> _splitLine(String line) {
    final List<String> cells = <String>[];
    final StringBuffer current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final String char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        cells.add(current.toString());
        current.clear();
        continue;
      }
      current.write(char);
    }
    cells.add(current.toString());
    return cells;
  }
}
