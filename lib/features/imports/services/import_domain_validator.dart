import '../constants/import_constants.dart';
import 'import_domain_lookup.dart';

/// Result of validating a CSV domain code cell within a department.
class ImportDomainValidation {
  const ImportDomainValidation({
    required this.isValid,
    this.domainId,
    this.canonicalCode,
    this.domainName,
    this.errorMessage,
    this.statusLabel,
  });

  final bool isValid;
  final String? domainId;
  final String? canonicalCode;
  final String? domainName;
  final String? errorMessage;
  final String? statusLabel;
}

/// Shared domain-code validation for problem CSV imports.
abstract final class ImportDomainValidator {
  ImportDomainValidator._();

  /// Validates [rawInput] as a domain **code** that exists under [departmentCode].
  static ImportDomainValidation validate({
    required String rawInput,
    required String? departmentCode,
    required ImportDomainLookup lookup,
  }) {
    final String trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const ImportDomainValidation(
        isValid: false,
        errorMessage: ImportConstants.missingDomainCodeMessage,
        statusLabel: 'Missing Domain',
      );
    }

    final String dept = (departmentCode ?? '').trim().toUpperCase();
    if (dept.isEmpty) {
      return const ImportDomainValidation(
        isValid: false,
        errorMessage: ImportConstants.domainRequiresDepartmentMessage,
        statusLabel: 'Invalid Domain',
      );
    }

    final ImportDomainInfo? match = lookup.findByCodeInDepartment(
      departmentCode: dept,
      domainCode: trimmed,
    );
    if (match == null) {
      return ImportDomainValidation(
        isValid: false,
        errorMessage: ImportConstants.domainNotFoundInDepartmentMessage(trimmed, dept),
        statusLabel: 'Invalid Domain',
      );
    }

    return ImportDomainValidation(
      isValid: true,
      domainId: match.domainId,
      canonicalCode: match.code,
      domainName: match.name,
      statusLabel: 'Valid',
    );
  }
}
