/// Strict CSV role labels for user import (case-sensitive — exact match required).
abstract final class CsvImportRoleConstants {
  CsvImportRoleConstants._();

  static const String faculty = 'FACULTY';
  static const String student = 'STUDENT';
  static const String judge = 'JUDGE';

  static const List<String> all = <String>[faculty, student, judge];

  static const Set<String> allSet = <String>{faculty, student, judge};

  static const Set<String> judgesPanelOnly = <String>{judge};

  /// Maps a validated CSV role label to the internal [UserRole] code.
  static String? toRoleCode(String csvRole) {
    return switch (csvRole) {
      faculty => 'FAC',
      student => 'STU',
      judge => 'JUD',
      _ => null,
    };
  }

  static String formatExpectedRoles(Set<String> allowed) {
    final List<String> ordered = all.where(allowed.contains).toList(growable: false);
    return ordered.join('\n');
  }
}
