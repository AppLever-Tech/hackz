import 'import_row_severity.dart';

/// Generic validated CSV row for import review UIs.
class ImportReviewRow {
  const ImportReviewRow({
    required this.rowNumber,
    required this.values,
    required this.severity,
    required this.statusLabel,
    this.messages = const <String>[],
    this.importable = false,
    this.metadata = const <String, String>{},
  });

  final int rowNumber;
  final Map<String, String> values;
  final ImportRowSeverity severity;
  final String statusLabel;
  final List<String> messages;
  final bool importable;
  final Map<String, String> metadata;

  String valueFor(String key) => (values[key] ?? '').trim();
}
