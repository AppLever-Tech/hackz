import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_type.dart';
import 'import_handler.dart';

/// Placeholder handler — Problems import is not implemented yet.
class ProblemsImportHandler implements ImportHandler {
  @override
  ImportType get type => ImportType.problems;

  @override
  String get title => 'Import Problems';

  @override
  String get templateFileName => 'hackz_problems_import_template.csv';

  @override
  String get templateCsv => 'title,description,category\n';

  @override
  List<String> get requiredHeaders => const <String>['title'];

  @override
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  ) async {
    throw UnimplementedError('Problems CSV import is not available yet.');
  }

  @override
  Future<ImportExecutionResult> executeImport(
    List<ImportReviewRow> rows,
    ImportHandlerContext context,
  ) async {
    throw UnimplementedError('Problems CSV import is not available yet.');
  }
}
