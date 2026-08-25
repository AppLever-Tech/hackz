import '../../problems/services/problem_title_display.dart';
import '../constants/import_constants.dart';
import '../models/import_review_row.dart';

/// Display-only titles for the Problem Import review table.
abstract final class ImportReviewTitleDisplay {
  static String forRow(ImportReviewRow row, List<ImportReviewRow> displayed) {
    final String title = row.valueFor(ImportConstants.titleColumnKey);
    if (title.isEmpty) return 'Untitled';
    if (!hasDuplicateTitleValue(
      title,
      displayed.map((ImportReviewRow r) => r.valueFor(ImportConstants.titleColumnKey)),
    )) {
      return title;
    }
    final String id = (row.metadata['sourceProblemId'] ??
            row.valueFor(ImportConstants.externalProblemIdColumnKey))
        .trim();
    if (id.isEmpty) return title;
    return '$id - $title';
  }
}
