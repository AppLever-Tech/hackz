import '../constants/import_constants.dart';
import 'google_source_client.dart';
import 'google_url_parser.dart';
import 'problem_normalized_row_mapper.dart';
import 'problem_source_extract_exception.dart';
import 'problem_source_extractor.dart';

/// Public Google Docs via document export (HTML/txt). No OAuth or Drive access.
class GoogleDocProblemExtractor implements ProblemSourceExtractor {
  const GoogleDocProblemExtractor();

  static final RegExp _tableRe = RegExp(r'<table\b[^>]*>[\s\S]*?</table>', caseSensitive: false);
  static final RegExp _rowRe = RegExp(r'<tr\b[^>]*>[\s\S]*?</tr>', caseSensitive: false);
  static final RegExp _cellRe = RegExp(r'<t[dh]\b[^>]*>[\s\S]*?</t[dh]>', caseSensitive: false);
  static final RegExp _headingRe = RegExp(r'<h([1-3])\b[^>]*>([\s\S]*?)</h\1>', caseSensitive: false);
  static final RegExp _numberedRe = RegExp(
    r'^\s*(?:problem(?:\s+statement)?\s*)?(\d+)\s*[\.\:\)]\s+(.+)$',
    caseSensitive: false,
  );
  static const Set<String> _skipHeadings = <String>{
    'contents',
    'table of contents',
    'introduction',
    'overview',
    'appendix',
    'references',
    'conclusion',
    'about',
    'instructions',
    'how to use',
    'abstract',
    'index',
    'preface',
    'acknowledgements',
    'acknowledgment',
  };

  @override
  Future<List<Map<String, String>>> extract(String sourceUrl) async {
    final GoogleSourceRef ref = GoogleUrlParser.parse(
      sourceUrl,
      expected: GoogleSourceType.document,
    );

    final String html = await GoogleSourceClient.getText(_htmlUri(ref), allowHtml: true);
    final List<Map<String, String>> fromHtml = _identifyFromHtml(html);

    List<Map<String, String>> rows = fromHtml;
    if (rows.isEmpty && !ref.published) {
      try {
        final String txt = await GoogleSourceClient.getText(_txtUri(ref), allowHtml: true);
        rows = _identifyFromPlainText(_htmlToText(txt));
      } on ProblemSourceExtractException {
        rows = const <Map<String, String>>[];
      }
    }

    if (rows.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.googleSourceNoProblemsMessage);
    }
    return ProblemNormalizedRowMapper.dedupe(rows);
  }

  Uri _htmlUri(GoogleSourceRef ref) {
    if (ref.published) {
      return Uri.parse('https://docs.google.com/document/d/e/${ref.id}/pub');
    }
    return Uri.parse('https://docs.google.com/document/d/${ref.id}/export?format=html');
  }

  Uri _txtUri(GoogleSourceRef ref) {
    return Uri.parse('https://docs.google.com/document/d/${ref.id}/export?format=txt');
  }

  List<Map<String, String>> _identifyFromHtml(String html) {
    final List<Map<String, String>> rows = <Map<String, String>>[];
    for (final Match table in _tableRe.allMatches(html)) {
      rows.addAll(_rowsFromTable(table.group(0)!));
    }

    final String withoutTables = html.replaceAll(_tableRe, '\n');
    rows.addAll(_rowsFromHeadings(withoutTables));

    if (rows.isEmpty) {
      rows.addAll(_identifyFromPlainText(_htmlToText(withoutTables)));
    }
    return rows.where(ProblemNormalizedRowMapper.isCandidate).toList(growable: false);
  }

  List<Map<String, String>> _rowsFromTable(String tableHtml) {
    final List<List<String>> matrix = <List<String>>[];
    for (final Match rowMatch in _rowRe.allMatches(tableHtml)) {
      final List<String> cells = <String>[];
      for (final Match cellMatch in _cellRe.allMatches(rowMatch.group(0)!)) {
        cells.add(_htmlToText(cellMatch.group(0)!));
      }
      if (cells.any((String cell) => cell.isNotEmpty)) matrix.add(cells);
    }
    if (matrix.isEmpty) return const <Map<String, String>>[];

    final int? headerIndex = ProblemNormalizedRowMapper.detectHeaderRow(matrix);
    if (headerIndex != null) {
      final List<String> headers = matrix[headerIndex];
      final List<Map<String, String>> rows = <Map<String, String>>[];
      for (var i = headerIndex + 1; i < matrix.length; i++) {
        final Map<String, String> mapped = ProblemNormalizedRowMapper.mapCells(headers, matrix[i]);
        if (ProblemNormalizedRowMapper.isCandidate(mapped)) rows.add(mapped);
      }
      if (rows.isNotEmpty) return rows;
    }

    return matrix
        .map(ProblemNormalizedRowMapper.fallbackTwoColumn)
        .where(ProblemNormalizedRowMapper.isCandidate)
        .toList(growable: false);
  }

  List<Map<String, String>> _rowsFromHeadings(String html) {
    final List<Match> headings = _headingRe.allMatches(html).toList(growable: false);
    if (headings.isEmpty) return const <Map<String, String>>[];

    final List<Map<String, String>> rows = <Map<String, String>>[];
    for (var i = 0; i < headings.length; i++) {
      final String title = _htmlToText(headings[i].group(2) ?? '');
      if (title.length < 3 || _skipHeadings.contains(title.toLowerCase())) continue;
      if (title.length > 180) continue;
      final int start = headings[i].end;
      final int end = i + 1 < headings.length ? headings[i + 1].start : html.length;
      final String description = _htmlToText(html.substring(start, end));
      final Map<String, String> row = ProblemNormalizedRowMapper.fallbackTwoColumn(
        <String>[title, description],
      );
      if (ProblemNormalizedRowMapper.isCandidate(row)) rows.add(row);
    }
    return rows;
  }

  List<Map<String, String>> _identifyFromPlainText(String text) {
    final List<String> lines = text
        .split('\n')
        .map((String line) => line.trim())
        .toList(growable: false);
    final List<Map<String, String>> rows = <Map<String, String>>[];

    String? title;
    final StringBuffer description = StringBuffer();

    void flush() {
      if (title == null) return;
      final Map<String, String> row = ProblemNormalizedRowMapper.fallbackTwoColumn(
        <String>[title!, description.toString().trim()],
      );
      if (ProblemNormalizedRowMapper.isCandidate(row)) rows.add(row);
      title = null;
      description.clear();
    }

    for (final String line in lines) {
      final Match? numbered = _numberedRe.firstMatch(line);
      if (numbered != null) {
        flush();
        title = numbered.group(2)!.trim();
        continue;
      }
      if (title == null) continue;
      if (line.isEmpty) {
        if (description.isNotEmpty) flush();
        continue;
      }
      if (description.isNotEmpty) description.writeln();
      description.write(line);
    }
    flush();
    return rows;
  }

  String _htmlToText(String html) {
    String text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(p|div|h[1-6]|li|tr)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (Match m) => String.fromCharCode(int.parse(m.group(1)!)),
        )
        .replaceAllMapped(
          RegExp(r'&#x([0-9a-fA-F]+);'),
          (Match m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
        );
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return text.trim();
  }
}
