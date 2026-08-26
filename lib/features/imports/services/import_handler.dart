import '../models/import_execution_result.dart';
import '../models/import_review_row.dart';
import '../models/import_summary.dart';
import '../models/import_type.dart';

/// Contract for all Hackz CSV import types.
abstract class ImportHandler {
  ImportType get type;

  String get title;

  String get templateFileName;

  String get templateCsv;

  List<String> get requiredHeaders;

  /// Columns shown in the review table. Defaults to [requiredHeaders].
  List<String> get reviewHeaders => requiredHeaders;

  /// Extra template help shown under the required-columns hint.
  String get columnGuidance => '';

  /// Optional template columns shown under required columns on the shared card.
  List<String> get optionalHeaders => expansionHeaders;

  /// Bullet points shown under the required/optional column hints.
  List<String> get columnGuidancePoints => const <String>[];

  /// Template bullets for the current import context (roles, defaults, etc.).
  List<String> templateGuidancePoints(ImportHandlerContext context) => columnGuidancePoints;

  /// Optional columns shown only when a review row is expanded.
  List<String> get expansionHeaders => const <String>[];

  /// When true, Import is disabled if any row has a blocking error.
  bool get blockImportOnAnyError => false;

  /// Preview summary after validation. Override to add type-specific counts.
  ImportSummary summarize(List<ImportReviewRow> rows) => ImportSummary.fromRows(rows);

  /// Validates parsed CSV rows and returns review rows (never imports here).
  Future<List<ImportReviewRow>> validateRows(
    List<Map<String, String>> rows,
    ImportHandlerContext context,
  );

  /// Imports only rows marked [ImportReviewRow.importable].
  ///
  /// [onProgress] is invoked with 1-based [current] and [total] importable rows.
  Future<ImportExecutionResult> executeImport(
    List<ImportReviewRow> rows,
    ImportHandlerContext context, {
    void Function(int current, int total)? onProgress,
  });
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
