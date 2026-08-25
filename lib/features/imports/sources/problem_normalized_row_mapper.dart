import '../constants/import_constants.dart';

/// Maps source columns onto the canonical Problem Import row keys.
abstract final class ProblemNormalizedRowMapper {
  static const List<String> canonicalKeys = <String>[
    ImportConstants.titleColumnKey,
    ImportConstants.descriptionColumnKey,
    ImportConstants.themeColumnKey,
    ImportConstants.issuingOrganisationColumnKey,
    ImportConstants.issuingDepartmentColumnKey,
    ImportConstants.externalProblemIdColumnKey,
  ];

  static const String categoryColumnKey = 'category';
  static const String tagsColumnKey = 'tags';

  static final Map<String, String> _aliases = <String, String>{
    'title': ImportConstants.titleColumnKey,
    'problem title': ImportConstants.titleColumnKey,
    'problem name': ImportConstants.titleColumnKey,
    'problem': ImportConstants.titleColumnKey,
    'name': ImportConstants.titleColumnKey,
    'challenge': ImportConstants.titleColumnKey,
    'ps title': ImportConstants.titleColumnKey,
    'statement title': ImportConstants.titleColumnKey,
    'description': ImportConstants.descriptionColumnKey,
    'problem description': ImportConstants.descriptionColumnKey,
    'problem statement': ImportConstants.descriptionColumnKey,
    'problem statements': ImportConstants.descriptionColumnKey,
    'details': ImportConstants.descriptionColumnKey,
    'statement': ImportConstants.descriptionColumnKey,
    'desc': ImportConstants.descriptionColumnKey,
    'about the problem': ImportConstants.descriptionColumnKey,
    'theme': ImportConstants.themeColumnKey,
    'issuing organisation': ImportConstants.issuingOrganisationColumnKey,
    'issuing organization': ImportConstants.issuingOrganisationColumnKey,
    'issuingorganisation': ImportConstants.issuingOrganisationColumnKey,
    'organisation': ImportConstants.issuingOrganisationColumnKey,
    'organization': ImportConstants.issuingOrganisationColumnKey,
    'issued by': ImportConstants.issuingOrganisationColumnKey,
    'organisation name': ImportConstants.issuingOrganisationColumnKey,
    'organization name': ImportConstants.issuingOrganisationColumnKey,
    'issuing department': ImportConstants.issuingDepartmentColumnKey,
    'issuingdepartment': ImportConstants.issuingDepartmentColumnKey,
    'ministry': ImportConstants.issuingDepartmentColumnKey,
    'department': ImportConstants.issuingDepartmentColumnKey,
    'external problem id': ImportConstants.externalProblemIdColumnKey,
    'externalproblemid': ImportConstants.externalProblemIdColumnKey,
    'problem id': ImportConstants.externalProblemIdColumnKey,
    'ps id': ImportConstants.externalProblemIdColumnKey,
    'sih id': ImportConstants.externalProblemIdColumnKey,
    'code': ImportConstants.externalProblemIdColumnKey,
    'category': categoryColumnKey,
    'tags': tagsColumnKey,
    'keywords': tagsColumnKey,
  };

  static String normalizeHeader(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  static String? canonicalKeyFor(String header) {
    final String normalized = normalizeHeader(header);
    if (normalized.isEmpty) return null;
    return _aliases[normalized];
  }

  static int headerScore(List<String> cells) {
    var score = 0;
    var hasTitle = false;
    var hasDescription = false;
    for (final String cell in cells) {
      final String? key = canonicalKeyFor(cell);
      if (key == ImportConstants.titleColumnKey) {
        hasTitle = true;
        score += 3;
      } else if (key == ImportConstants.descriptionColumnKey) {
        hasDescription = true;
        score += 3;
      } else if (key != null) {
        score += 1;
      }
    }
    if (hasTitle && hasDescription) score += 2;
    return score;
  }

  static int? detectHeaderRow(List<List<String>> matrix, {int scanLimit = 15}) {
    var bestScore = 0;
    int? bestIndex;
    final int limit = matrix.length < scanLimit ? matrix.length : scanLimit;
    for (var i = 0; i < limit; i++) {
      final int score = headerScore(matrix[i]);
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }
    if (bestScore < 3) return null;
    return bestIndex;
  }

  static Map<String, String> mapRow(Map<String, String> row) {
    final Map<String, String> out = <String, String>{
      for (final String key in canonicalKeys) key: '',
      categoryColumnKey: '',
      tagsColumnKey: '',
    };
    for (final MapEntry<String, String> entry in row.entries) {
      final String? key = canonicalKeyFor(entry.key);
      if (key == null) continue;
      final String value = entry.value.trim();
      if (value.isEmpty) continue;
      if ((out[key] ?? '').isEmpty) out[key] = value;
    }
    return out;
  }

  static Map<String, String> mapCells(List<String> headers, List<String> cells) {
    final Map<String, String> raw = <String, String>{};
    for (var i = 0; i < headers.length; i++) {
      final String header = headers[i].trim();
      if (header.isEmpty) continue;
      raw[header] = i < cells.length ? cells[i].trim() : '';
    }
    return mapRow(raw);
  }

  /// CSV/Excel convention: first non-empty row is headers; skip fully empty rows.
  static List<Map<String, String>> rowsFromFirstHeaderRow(List<List<String>> matrix) {
    final List<List<String>> nonempty = matrix
        .where((List<String> row) => row.any((String cell) => cell.trim().isNotEmpty))
        .toList(growable: false);
    if (nonempty.length < 2) return const <Map<String, String>>[];

    final List<String> headers = nonempty.first;
    final List<Map<String, String>> rows = <Map<String, String>>[];
    for (var i = 1; i < nonempty.length; i++) {
      final Map<String, String> mapped = mapCells(headers, nonempty[i]);
      if (!isEmpty(mapped)) rows.add(mapped);
    }
    return rows;
  }

  /// Tabular sources where the header row may not be first (Google Sheets).
  static List<Map<String, String>> rowsFromDetectedHeaders(List<List<String>> matrix) {
    final int? headerIndex = detectHeaderRow(matrix);
    final List<Map<String, String>> rows = <Map<String, String>>[];

    if (headerIndex != null) {
      final List<String> headers = matrix[headerIndex];
      for (var i = headerIndex + 1; i < matrix.length; i++) {
        if (matrix[i].every((String cell) => cell.trim().isEmpty)) continue;
        final Map<String, String> mapped = mapCells(headers, matrix[i]);
        if (isCandidate(mapped)) rows.add(mapped);
      }
    }

    if (rows.isEmpty) {
      for (final List<String> cells in matrix) {
        if (cells.every((String cell) => cell.trim().isEmpty)) continue;
        final Map<String, String> mapped = fallbackTwoColumn(cells);
        if (isCandidate(mapped)) rows.add(mapped);
      }
    }
    return rows;
  }

  static Map<String, String> fallbackTwoColumn(List<String> cells) {
    return <String, String>{
      ImportConstants.titleColumnKey: cells.isNotEmpty ? cells.first.trim() : '',
      ImportConstants.descriptionColumnKey: cells.length > 1 ? cells[1].trim() : '',
      ImportConstants.themeColumnKey: '',
      ImportConstants.issuingOrganisationColumnKey: '',
      ImportConstants.issuingDepartmentColumnKey: '',
      ImportConstants.externalProblemIdColumnKey: '',
    };
  }

  static bool isEmpty(Map<String, String> row) =>
      row.values.every((String value) => value.trim().isEmpty);

  static bool isLikelyHeaderRecord(Map<String, String> row) {
    final String title = (row[ImportConstants.titleColumnKey] ?? '').trim().toLowerCase();
    final String description = (row[ImportConstants.descriptionColumnKey] ?? '').trim().toLowerCase();
    const Set<String> headerTitles = <String>{
      'title',
      'problem',
      'problem title',
      'name',
      's no',
      'sr no',
      'sl no',
      'si no',
    };
    if (headerTitles.contains(title)) return true;
    if (title == 'description' || description == 'description' || description == 'problem statement') {
      return true;
    }
    return false;
  }

  static bool isCandidate(Map<String, String> row) {
    if (isEmpty(row) || isLikelyHeaderRecord(row)) return false;
    final String title = (row[ImportConstants.titleColumnKey] ?? '').trim();
    final String description = (row[ImportConstants.descriptionColumnKey] ?? '').trim();
    return title.length >= 3 || description.length >= 12;
  }

  static List<Map<String, String>> dedupe(List<Map<String, String>> rows) {
    final Map<String, Map<String, String>> byTitle = <String, Map<String, String>>{};
    final List<Map<String, String>> untitled = <Map<String, String>>[];
    for (final Map<String, String> row in rows) {
      final String title = (row[ImportConstants.titleColumnKey] ?? '').trim().toLowerCase();
      if (title.isEmpty) {
        untitled.add(row);
        continue;
      }
      final Map<String, String>? existing = byTitle[title];
      if (existing == null) {
        byTitle[title] = row;
        continue;
      }
      final int existingLen = (existing[ImportConstants.descriptionColumnKey] ?? '').length;
      final int nextLen = (row[ImportConstants.descriptionColumnKey] ?? '').length;
      if (nextLen > existingLen) byTitle[title] = row;
    }
    return <Map<String, String>>[...byTitle.values, ...untitled];
  }
}
