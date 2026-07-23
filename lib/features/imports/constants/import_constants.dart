import '../../user/constants/csv_import_role_constants.dart';

/// Shared CSV import column keys and validation copy.
abstract final class ImportConstants {
  ImportConstants._();

  static const String departmentColumnKey = 'department';
  static const String domainCodeColumnKey = 'domainCode';

  static String requiredColumnsHint(List<String> headers) =>
      'Required columns: ${headers.join(', ')}';

  static String invalidRoleMessage(Set<String> allowedRoles) {
    final String expected = CsvImportRoleConstants.formatExpectedRoles(allowedRoles);
    return 'Invalid Role\n\nExpected one of:\n\n$expected';
  }

  static const String missingRoleMessage = 'Missing role';

  static const String missingDepartmentCodeMessage = 'Missing department code';

  static const String missingDomainCodeMessage = 'Missing domain code';

  static const String domainRequiresDepartmentMessage =
      'Domain code requires a valid department code in the same row.';

  static String departmentNotFoundMessage(String code) =>
      'Department Code "$code" not found.\n\n'
      'Please create the department first under Department Management and retry the import.';

  static String domainNotFoundInDepartmentMessage(String domainCode, String departmentCode) =>
      'Domain Code "$domainCode" not found in department "$departmentCode".\n\n'
      'Create the domain under Domains for that department and retry the import.';
}
