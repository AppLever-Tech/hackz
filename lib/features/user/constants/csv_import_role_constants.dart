import '../models/enums/user_role.dart';

/// Strict CSV role labels for user import (case-sensitive — exact match required).
abstract final class CsvImportRoleConstants {
  CsvImportRoleConstants._();

  static const String teamMember = 'TEAM_MEMBER';
  static const String coordinator = 'COORDINATOR';
  static const String judge = 'JUDGE';

  static const List<String> all = <String>[teamMember, coordinator, judge];

  static const Set<String> allSet = <String>{teamMember, coordinator, judge};

  static const Set<String> judgesPanelOnly = <String>{judge};

  /// Maps a validated CSV role label to the internal [UserRole] code.
  static String? toRoleCode(String csvRole) {
    return switch (csvRole) {
      teamMember => UserRole.teamMember.code,
      coordinator => UserRole.coordinator.code,
      judge => UserRole.judge.code,
      _ => null,
    };
  }

  static String formatExpectedRoles(Set<String> allowed) {
    final List<String> ordered = all.where(allowed.contains).toList(growable: false);
    return ordered.join('\n');
  }
}
