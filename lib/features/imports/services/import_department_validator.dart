import '../../organization/models/department_model.dart';
import '../constants/import_constants.dart';
import 'import_department_lookup.dart';

/// Result of validating a CSV department cell.
class ImportDepartmentValidation {
  const ImportDepartmentValidation({
    required this.isValid,
    this.canonicalCode,
    this.departmentName,
    this.errorMessage,
    this.statusLabel,
    this.needsResolution = false,
    this.rawInput = '',
  });

  final bool isValid;
  final String? canonicalCode;
  final String? departmentName;
  final String? errorMessage;
  final String? statusLabel;
  final bool needsResolution;
  final String rawInput;
}

/// Shared department validation for CSV import types.
abstract final class ImportDepartmentValidator {
  ImportDepartmentValidator._();

  /// Empty input uses [defaultCode]/[defaultName]. Non-empty values must resolve
  /// to an org department (code, name, normalized match, alias, or session mapping).
  static ImportDepartmentValidation validate({
    required String rawInput,
    required ImportDepartmentLookup lookup,
    String? defaultCode,
    String? defaultName,
    Map<String, ImportDepartmentMapping> resolutions = const <String, ImportDepartmentMapping>{},
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

    final ImportDepartmentMapping? mapped = resolutions[DepartmentModel.normalizeKey(trimmed)];
    if (mapped != null) {
      return ImportDepartmentValidation(
        isValid: true,
        canonicalCode: mapped.code,
        departmentName: mapped.name.isNotEmpty ? mapped.name : lookup.codeToName[mapped.code],
        statusLabel: 'Valid',
        rawInput: trimmed,
      );
    }

    final ImportDepartmentInfo? match = lookup.resolve(trimmed);
    if (match != null) {
      return ImportDepartmentValidation(
        isValid: true,
        canonicalCode: match.code,
        departmentName: match.name,
        statusLabel: 'Valid',
        rawInput: trimmed,
      );
    }

    return ImportDepartmentValidation(
      isValid: false,
      needsResolution: true,
      rawInput: trimmed,
      errorMessage: ImportConstants.departmentUnresolvedMessage(trimmed),
      statusLabel: 'Unresolved Department',
    );
  }
}
