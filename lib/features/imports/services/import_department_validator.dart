import '../constants/import_constants.dart';
import 'import_department_lookup.dart';

/// Result of validating a CSV department code cell.
class ImportDepartmentValidation {
  const ImportDepartmentValidation({
    required this.isValid,
    this.canonicalCode,
    this.departmentName,
    this.errorMessage,
    this.statusLabel,
  });

  final bool isValid;
  final String? canonicalCode;
  final String? departmentName;
  final String? errorMessage;
  final String? statusLabel;
}

/// Shared department-code validation for all CSV import types.
abstract final class ImportDepartmentValidator {
  ImportDepartmentValidator._();

  /// Validates [rawInput] as an org department **code** (not a display name).
  static ImportDepartmentValidation validate({
    required String rawInput,
    required ImportDepartmentLookup lookup,
    String? defaultCode,
    String? defaultName,
  }) {
    final String trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      final String code = (defaultCode ?? '').trim().toUpperCase();
      if (code.isEmpty) {
        return const ImportDepartmentValidation(
          isValid: false,
          errorMessage: ImportConstants.missingDepartmentCodeMessage,
          statusLabel: 'Missing Department',
        );
      }
      final String name = (defaultName ?? '').trim();
      return ImportDepartmentValidation(
        isValid: true,
        canonicalCode: code,
        departmentName: name.isNotEmpty ? name : lookup.codeToName[code],
        statusLabel: 'Valid',
      );
    }

    final String code = trimmed.toUpperCase();
    if (!lookup.codes.contains(code)) {
      return ImportDepartmentValidation(
        isValid: false,
        errorMessage: ImportConstants.departmentNotFoundMessage(trimmed),
        statusLabel: 'Invalid Department',
      );
    }

    return ImportDepartmentValidation(
      isValid: true,
      canonicalCode: code,
      departmentName: lookup.codeToName[code],
      statusLabel: 'Valid',
    );
  }
}
