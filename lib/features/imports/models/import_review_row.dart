import 'import_row_severity.dart';

/// Generic validated CSV row for import review UIs.
class ImportReviewRow {
  const ImportReviewRow({
    required this.rowNumber,
    required this.values,
    required this.severity,
    required this.statusLabel,
    this.messages = const <String>[],
    this.errorMessages = const <String>[],
    this.warningMessages = const <String>[],
    this.importable = false,
    this.excluded = false,
    this.metadata = const <String, String>{},
  });

  final int rowNumber;
  final Map<String, String> values;
  final ImportRowSeverity severity;
  final String statusLabel;
  final List<String> messages;
  final List<String> errorMessages;
  final List<String> warningMessages;
  final bool importable;
  final bool excluded;
  final Map<String, String> metadata;

  String valueFor(String key) => (values[key] ?? '').trim();

  List<String> get displayErrorMessages {
    final List<String> explicit = _nonEmpty(errorMessages);
    if (explicit.isNotEmpty) return explicit;
    if (_nonEmpty(warningMessages).isNotEmpty) return const <String>[];
    if (severity == ImportRowSeverity.error) return _nonEmpty(messages);
    return const <String>[];
  }

  List<String> get displayWarningMessages {
    final List<String> explicit = _nonEmpty(warningMessages);
    if (explicit.isNotEmpty) return explicit;
    if (_nonEmpty(errorMessages).isNotEmpty) return const <String>[];
    if (severity == ImportRowSeverity.warning) return _nonEmpty(messages);
    if (severity == ImportRowSeverity.valid) return _nonEmpty(messages);
    return const <String>[];
  }

  static List<String> _nonEmpty(List<String> values) {
    return values.where((String value) => value.trim().isNotEmpty).toList(growable: false);
  }

  ImportReviewRow copyWith({
    Map<String, String>? values,
    ImportRowSeverity? severity,
    String? statusLabel,
    List<String>? messages,
    List<String>? errorMessages,
    List<String>? warningMessages,
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
      errorMessages: errorMessages ?? this.errorMessages,
      warningMessages: warningMessages ?? this.warningMessages,
      importable: importable ?? this.importable,
      excluded: excluded ?? this.excluded,
      metadata: metadata ?? this.metadata,
    );
  }
}
