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
    this.excluded = false,
    this.metadata = const <String, String>{},
  });

  final int rowNumber;
  final Map<String, String> values;
  final ImportRowSeverity severity;
  final String statusLabel;
  final List<String> messages;
  final bool importable;
  final bool excluded;
  final Map<String, String> metadata;

  String valueFor(String key) => (values[key] ?? '').trim();

  ImportReviewRow copyWith({
    Map<String, String>? values,
    ImportRowSeverity? severity,
    String? statusLabel,
    List<String>? messages,
    bool? importable,
    bool? excluded,
    Map<String, String>? metadata,
  }) {
    return ImportReviewRow(
      rowNumber: rowNumber,
      values: values ?? this.values,
      severity: severity ?? this.severity,
      statusLabel: statusLabel ?? this.statusLabel,
      messages: messages ?? this.messages,
      importable: importable ?? this.importable,
      excluded: excluded ?? this.excluded,
      metadata: metadata ?? this.metadata,
    );
  }
}
