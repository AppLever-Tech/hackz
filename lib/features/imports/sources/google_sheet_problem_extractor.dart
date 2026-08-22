import '../constants/import_constants.dart';
import '../services/csv_parser_service.dart';
import 'google_source_client.dart';
import 'google_url_parser.dart';
import 'problem_normalized_row_mapper.dart';
import 'problem_source_extract_exception.dart';
import 'problem_source_extractor.dart';

/// Public Google Sheets via spreadsheet export / gviz CSV. No OAuth.
class GoogleSheetProblemExtractor implements ProblemSourceExtractor {
  const GoogleSheetProblemExtractor();

  @override
  Future<List<Map<String, String>>> extract(String sourceUrl) async {
    final GoogleSourceRef ref = GoogleUrlParser.parse(
      sourceUrl,
      expected: GoogleSourceType.spreadsheet,
    );

    String csv;
    try {
      csv = await GoogleSourceClient.getText(_exportCsvUri(ref), allowHtml: false);
    } on ProblemSourceExtractException {
      if (ref.published) rethrow;
      csv = await GoogleSourceClient.getText(_gvizCsvUri(ref), allowHtml: false);
    }

    final List<List<String>> matrix = CsvParserService.parseMatrix(csv);
    if (matrix.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.googleSourceEmptyMessage);
    }

    final List<Map<String, String>> rows = _identifyProblems(matrix);
    if (rows.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.googleSourceNoProblemsMessage);
    }
    return ProblemNormalizedRowMapper.dedupe(rows);
  }

  Uri _exportCsvUri(GoogleSourceRef ref) {
    if (ref.published) {
      return Uri.parse(
        'https://docs.google.com/spreadsheets/d/e/${ref.id}/pub?output=csv'
        '${ref.gid == null ? '' : '&gid=${ref.gid}'}',
      );
    }
    final String gid = ref.gid ?? '0';
    return Uri.parse(
      'https://docs.google.com/spreadsheets/d/${ref.id}/export?format=csv&gid=$gid',
    );
  }

  Uri _gvizCsvUri(GoogleSourceRef ref) {
    final String gid = ref.gid ?? '0';
    return Uri.parse(
      'https://docs.google.com/spreadsheets/d/${ref.id}/gviz/tq?tqx=out:csv&gid=$gid',
    );
  }

  List<Map<String, String>> _identifyProblems(List<List<String>> matrix) {
    final int? headerIndex = ProblemNormalizedRowMapper.detectHeaderRow(matrix);
    final List<Map<String, String>> rows = <Map<String, String>>[];

    if (headerIndex != null) {
      final List<String> headers = matrix[headerIndex];
      for (var i = headerIndex + 1; i < matrix.length; i++) {
        final Map<String, String> mapped = ProblemNormalizedRowMapper.mapCells(headers, matrix[i]);
        if (ProblemNormalizedRowMapper.isCandidate(mapped)) rows.add(mapped);
      }
    }

    if (rows.isEmpty) {
      for (final List<String> cells in matrix) {
        if (cells.every((String cell) => cell.trim().isEmpty)) continue;
        final Map<String, String> mapped = ProblemNormalizedRowMapper.fallbackTwoColumn(cells);
        if (ProblemNormalizedRowMapper.isCandidate(mapped)) rows.add(mapped);
      }
    }

    return rows;
  }
}
