import 'import_review_row.dart';
import 'import_row_severity.dart';

/// Optional extra preview counts (e.g. Teams / Members) shown instead of the
/// default Total / Valid row chips when non-empty.
class ImportPreviewCount {
  const ImportPreviewCount({required this.label, required this.value});

  final String label;
  final int value;
}

class ImportSummary {
  const ImportSummary({
    required this.totalRows,
    required this.validRows,
    required this.warningRows,
    required this.errorRows,
    required this.skippedRows,
    this.previewCounts = const <ImportPreviewCount>[],
  });

  final int totalRows;
  final int validRows;
  final int warningRows;
  final int errorRows;
  final int skippedRows;
  final List<ImportPreviewCount> previewCounts;

  factory ImportSummary.fromRows(
    List<ImportReviewRow> rows, {
    List<ImportPreviewCount> previewCounts = const <ImportPreviewCount>[],
  }) {
    var valid = 0;
    var warnings = 0;
    var errors = 0;
    var skipped = 0;
    for (final ImportReviewRow row in rows) {
      if (row.excluded) {
        skipped++;
        continue;
      }
      switch (row.severity) {
        case ImportRowSeverity.valid:
          if (row.importable) {
            valid++;
          } else {
            skipped++;
          }
        case ImportRowSeverity.warning:
          warnings++;
          if (row.importable) {
            valid++;
          } else {
            skipped++;
          }
        case ImportRowSeverity.error:
          errors++;
      }
    }
    return ImportSummary(
      totalRows: rows.length,
      validRows: valid,
      warningRows: warnings,
      errorRows: errors,
      skippedRows: skipped,
      previewCounts: previewCounts,
    );
  }
}
