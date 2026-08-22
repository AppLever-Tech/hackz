import 'google_doc_problem_extractor.dart';
import 'google_sheet_problem_extractor.dart';
import 'problem_import_source_kind.dart';
import 'problem_source_extractor.dart';

abstract final class ProblemSourceExtractors {
  static ProblemSourceExtractor forKind(ProblemImportSourceKind kind) {
    return switch (kind) {
      ProblemImportSourceKind.googleDoc => const GoogleDocProblemExtractor(),
      ProblemImportSourceKind.googleSheet => const GoogleSheetProblemExtractor(),
      ProblemImportSourceKind.csv =>
        throw StateError('CSV import uses the existing file-picker flow.'),
    };
  }
}
