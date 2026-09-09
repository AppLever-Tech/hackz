import '../../organization/models/department_model.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../constants/import_constants.dart';
import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';
import '../models/import_type.dart';
import 'import_handler.dart';
import 'team_registration_import_handler.dart';
import 'user_import_handler.dart';

/// Unique CSV department value that could not be resolved automatically.
class ImportUnresolvedDepartment {
  const ImportUnresolvedDepartment({
    required this.rawValue,
    required this.rowCount,
  });

  final String rawValue;
  final int rowCount;

  String get normalizedKey => DepartmentModel.normalizeKey(rawValue);
}

/// RBAC for the import department-resolution step. Uses existing Hackz roles only.
abstract final class ImportDepartmentResolutionPolicy {
  ImportDepartmentResolutionPolicy._();

  static bool supports(ImportType type) =>
      type == ImportType.users || type == ImportType.teamRegistration;

  static UserModel? actorOf(ImportHandlerContext context) {
    if (context is UserImportHandlerContext) return context.config.actor;
    if (context is TeamRegistrationImportHandlerContext) return context.actor;
    return null;
  }

  static UserRole? actorRoleOf(ImportHandlerContext context) {
    final UserModel? actor = actorOf(context);
    if (actor == null) return null;
    return UserRole.fromCode(actor.role);
  }

  static bool canMap(UserRole? role) =>
      role == UserRole.collegeAdmin || role == UserRole.departmentAdmin || role == UserRole.coordinator;

  static bool canCreateDepartment(UserRole? role) => role == UserRole.collegeAdmin;

  static bool canAssignAdministrator(UserRole? role) =>
      role == UserRole.collegeAdmin || role == UserRole.departmentAdmin;

  static bool canCreateDepartmentAdmin(UserRole? role) => role == UserRole.collegeAdmin;

  static bool canSaveAlias(UserRole? role) =>
      role == UserRole.collegeAdmin || role == UserRole.departmentAdmin;

  static List<ImportUnresolvedDepartment> unresolvedFromRows(List<ImportReviewRow> rows) {
    final Map<String, ImportUnresolvedDepartment> byKey = <String, ImportUnresolvedDepartment>{};
    for (final ImportReviewRow row in rows) {
      if (row.metadata['departmentNeedsResolution'] != '1') continue;
      final String raw = (row.metadata['departmentRaw'] ?? row.valueFor(ImportConstants.departmentColumnKey)).trim();
      if (raw.isEmpty) continue;
      final String key = DepartmentModel.normalizeKey(raw);
      final ImportUnresolvedDepartment? existing = byKey[key];
      if (existing == null) {
        byKey[key] = ImportUnresolvedDepartment(rawValue: raw, rowCount: 1);
      } else {
        byKey[key] = ImportUnresolvedDepartment(rawValue: existing.rawValue, rowCount: existing.rowCount + 1);
      }
    }
    return byKey.values.toList(growable: false);
  }

  /// Returns a blocking message when the file is not ready for an all-or-nothing import.
  static String? atomicBlockReason(List<ImportReviewRow> rows) {
    if (rows.any((ImportReviewRow r) => r.metadata['departmentNeedsResolution'] == '1')) {
      return ImportConstants.departmentImportBlockedMessage;
    }
    if (rows.any((ImportReviewRow r) => r.severity == ImportRowSeverity.error)) {
      return ImportConstants.importValidationBlockedMessage;
    }
    if (rows.any((ImportReviewRow r) => !r.importable)) {
      return ImportConstants.partialImportBlockedMessage;
    }
    return null;
  }
}
