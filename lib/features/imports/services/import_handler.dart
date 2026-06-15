import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_type.dart';

/// Contract for all Hackz CSV import types.
abstract class ImportHandler {
  ImportType get type;

  String get title;

  String get templateFileName;

  String get templateCsv;

  List<String> get requiredHeaders;

  /// Validates parsed CSV rows and returns review rows (never imports here).
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  );

  /// Imports only rows marked [ImportReviewRow.importable].
  Future<ImportExecutionResult> executeImport(
    List<ImportReviewRow> rows,
    ImportHandlerContext context,
  );
}

/// Shared runtime context passed to import handlers.
class ImportHandlerContext {
  const ImportHandlerContext({
    required this.actorUserId,
    required this.orgId,
    required this.defaultDepartmentName,
    required this.defaultDepartmentCode,
  });

  final String actorUserId;
  final String orgId;
  final String defaultDepartmentName;
  final String defaultDepartmentCode;

  /// CSV role labels shown in Supported Values (user import only).
  Set<String>? get supportedCsvRoles => null;
}
