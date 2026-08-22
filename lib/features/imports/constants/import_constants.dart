import '../../user/constants/csv_import_role_constants.dart';

/// Shared CSV import column keys and validation copy.
abstract final class ImportConstants {
  ImportConstants._();

  static const String departmentColumnKey = 'department';
  static const String teamNameColumnKey = 'teamName';
  static const String phoneColumnKey = 'phone';
  static const String firstNameColumnKey = 'firstName';
  static const String lastNameColumnKey = 'lastName';
  static const String emailColumnKey = 'email';
  static const String roleColumnKey = 'role';
  static const String organisationColumnKey = 'organisation';
  static const String isTeamLeaderColumnKey = 'isTeamLeader';
  static const String titleColumnKey = 'title';
  static const String descriptionColumnKey = 'description';
  static const String themeColumnKey = 'theme';
  static const String issuingOrganisationColumnKey = 'issuingOrganisation';
  static const String issuingDepartmentColumnKey = 'issuingDepartment';
  static const String externalProblemIdColumnKey = 'externalProblemId';

  static String requiredColumnsHint(List<String> headers) =>
      'Required columns: ${headers.map(headerLabel).join(', ')}';

  static String optionalColumnsHint(List<String> headers) =>
      'Optional columns: ${headers.map(headerLabel).join(', ')}';

  static String headerLabel(String key) {
    if (key == externalProblemIdColumnKey) return 'Problem ID';
    if (key == isTeamLeaderColumnKey) return 'Team Leader';
    if (key == organisationColumnKey) return 'Organisation';
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

  static const String invalidGoogleUrlMessage =
      'Enter a valid Google Doc or Google Sheet URL.';

  static const String unsupportedGoogleUrlMessage =
      'This URL is not a supported Google Doc or Google Sheet link.';

  static const String googleDocExpectedMessage =
      'This looks like a Google Sheet. Choose Google Sheet as the import source.';

  static const String googleSheetExpectedMessage =
      'This looks like a Google Doc. Choose Google Doc as the import source.';

  static const String googleSourcePrivateMessage =
      'This Google file is private or not shared. Share it as “Anyone with the link can view” and try again.';

  static const String googleSourceInaccessibleMessage =
      'This Google file could not be reached. Check the URL, sharing settings, and your connection.';

  static const String googleSourceEmptyMessage =
      'The Google file did not contain any content to import.';

  static const String googleSourceNoProblemsMessage =
      'No problem statements could be identified in this source. Use a table or headings with titles and descriptions.';

  static const String googleSourceTimeoutMessage =
      'Timed out while fetching the Google file. Try again.';
}
