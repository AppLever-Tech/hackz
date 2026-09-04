enum UserRole {
  sysAdmin('SADM'),
  collegeAdmin('CADM'),
  departmentAdmin('DADM'),
  judge('JUD'),
  teamMember('TMEM'),
  coordinator('COO');

  final String code;
  const UserRole(this.code);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => UserRole.teamMember,
    );
  }

  static String _normalized(String? code) => (code ?? '').trim().toUpperCase();

  /// Platform operator — never part of college or department user directories.
  static bool isSysAdminCode(String? code) => _normalized(code) == sysAdmin.code;

  /// Department People & Teams directory: team members, coordinators, and judges.
  static bool isDepartmentPeopleCode(String? code) {
    final String role = _normalized(code);
    return role == teamMember.code || role == coordinator.code || role == judge.code;
  }
}
