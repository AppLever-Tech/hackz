enum UserRole {
  sysAdmin('SADM'),
  collegeAdmin('CADM'),
  departmentAdmin('DADM'),
  judge('JUD'),
  student('STU'),
  coordinator('COO');

  final String code;
  const UserRole(this.code);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => UserRole.student,
    );
  }
}
