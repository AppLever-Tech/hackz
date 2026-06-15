import '../../user/constants/csv_import_role_constants.dart';

/// Shared CSV import column keys and validation copy.
abstract final class ImportConstants {
  ImportConstants._();

  static const String departmentColumnKey = 'department';

  static String requiredColumnsHint(List<String> headers) =>
      'Required columns: ${headers.join(', ')}';

  static String invalidRoleMessage(Set<String> allowedRoles) {
    final String expected = CsvImportRoleConstants.formatExpectedRoles(allowedRoles);
    return 'Invalid Role\n\nExpected one of:\n\n$expected';
  }

  static const String missingRoleMessage = 'Missing role';

  static const String missingDepartmentCodeMessage = 'Missing department code';

  static String departmentNotFoundMessage(String code) =>
      'Department Code "$code" not found.\n\n'
      'Please create the department first under Department Management and retry the import.';
}
