import '../../user/constants/csv_import_role_constants.dart';

/// Shared CSV import column keys and validation copy.
abstract final class ImportConstants {
  ImportConstants._();

  static const String departmentColumnKey = 'department';
  static const String titleColumnKey = 'title';
  static const String descriptionColumnKey = 'description';
  static const String issuingOrganisationColumnKey = 'issuingOrganisation';
  static const String issuingDepartmentColumnKey = 'issuingDepartment';
  static const String externalProblemIdColumnKey = 'externalProblemId';

  static String requiredColumnsHint(List<String> headers) =>
      'Required columns: ${headers.join(', ')}';

  static String headerLabel(String key) {
    if (key.isEmpty) return key;
    final String spaced = key.replaceAllMapped(RegExp(r'[A-Z]'), (Match m) => ' ${m[0]}').trim();
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  static String invalidRoleMessage(Set<String> allowedRoles) {
    final String expected = CsvImportRoleConstants.formatExpectedRoles(allowedRoles);
    return 'Invalid Role\n\nExpected one of:\n\n$expected';
  }

  static const String missingRoleMessage = 'Missing role';

  static const String missingDepartmentCodeMessage = 'Missing department code';

  static String departmentNotFoundMessage(String code) =>
      'Department Code "$code" not found.\n\n'
      'Please create the department first under Department Management and retry the import.';

  static const String missingImportDepartmentMessage =
      'Select a department before importing problems.';

  static const String generalProblemDomainFailedMessage =
      'Could not resolve or create the "General Problem" domain for this department.';
}
