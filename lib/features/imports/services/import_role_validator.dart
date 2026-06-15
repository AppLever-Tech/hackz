import '../../user/constants/csv_import_role_constants.dart';
import '../constants/import_constants.dart';

/// Result of validating a CSV role cell (user import only).
class ImportRoleValidation {
  const ImportRoleValidation({
    required this.isValid,
    this.roleCode,
    this.errorMessage,
    this.statusLabel,
  });

  final bool isValid;
  final String? roleCode;
  final String? errorMessage;
  final String? statusLabel;
}

/// Strict, case-sensitive CSV role validation.
abstract final class ImportRoleValidator {
  ImportRoleValidator._();

  static ImportRoleValidation validate({
    required String rawInput,
    required Set<String> allowedCsvRoles,
  }) {
    final String trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const ImportRoleValidation(
        isValid: false,
        errorMessage: ImportConstants.missingRoleMessage,
        statusLabel: 'Missing Role',
      );
    }

    if (!allowedCsvRoles.contains(trimmed)) {
      return ImportRoleValidation(
        isValid: false,
        errorMessage: ImportConstants.invalidRoleMessage(allowedCsvRoles),
        statusLabel: 'Invalid Role',
      );
    }

    final String? roleCode = CsvImportRoleConstants.toRoleCode(trimmed);
    if (roleCode == null) {
      return ImportRoleValidation(
        isValid: false,
        errorMessage: ImportConstants.invalidRoleMessage(allowedCsvRoles),
        statusLabel: 'Invalid Role',
      );
    }

    return ImportRoleValidation(
      isValid: true,
      roleCode: roleCode,
      statusLabel: 'Valid',
    );
  }
}
