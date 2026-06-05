import 'import_review_row.dart';
import 'import_row_severity.dart';

class ImportSummary {
  const ImportSummary({
    required this.totalRows,
    required this.validRows,
    required this.warningRows,
    required this.errorRows,
    required this.skippedRows,
  });

  final int totalRows;
  final int validRows;
  final int warningRows;
  final int errorRows;
  final int skippedRows;

  factory ImportSummary.fromRows(List<ImportReviewRow> rows) {
    var valid = 0;
    var warnings = 0;
    var errors = 0;
    var skipped = 0;
    for (final ImportReviewRow row in rows) {
      switch (row.severity) {
        case ImportRowSeverity.valid:
          if (row.importable) {
            valid++;
          } else {
            skipped++;
          }
        case ImportRowSeverity.warning:
          warnings++;
          skipped++;
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
    );
  }
}
