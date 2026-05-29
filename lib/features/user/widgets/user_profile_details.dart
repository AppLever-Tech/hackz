import '../models/profiles/user_profile.dart';

/// Read-only profile field rows for workspace and admin views.
abstract final class UserProfileDetails {
  static List<({String label, String value})> rows(UserProfile? profile) {
    if (profile == null || profile.isEmpty) return const <({String label, String value})>[];

    final List<({String label, String value})> rows = <({String label, String value})>[];

    final professional = profile.professionalProfile;
    if (professional != null && !professional.isEmpty) {
      _add(rows, 'Company', professional.company);
      _add(rows, 'Designation', professional.designation);
      if (professional.yearsOfExperience > 0) {
        rows.add((label: 'Experience', value: '${professional.yearsOfExperience} years'));
      }
      _addList(rows, 'Expertise', professional.expertiseAreas);
    }

    final student = profile.studentProfile;
    if (student != null && !student.isEmpty) {
      _add(rows, 'Program', student.program);
      _add(rows, 'Year of study', student.yearOfStudy);
      _addList(rows, 'Skills', student.skills);
    }

    final faculty = profile.facultyProfile;
    if (faculty != null && !faculty.isEmpty) {
      _add(rows, 'Specialization', faculty.specialization);
      _addList(rows, 'Research interests', faculty.researchInterests);
    }

    final judge = profile.judgeProfile;
    if (judge != null && !judge.isEmpty) {
      if (judge.judgeType != null) {
        rows.add((label: 'Judge type', value: judge.judgeType!.label));
      }
      _addList(rows, 'Evaluation domains', judge.evaluationDomains);
    }

    final deptAdmin = profile.departmentAdminProfile;
    if (deptAdmin != null && !deptAdmin.isEmpty) {
      _add(rows, 'Department designation', deptAdmin.officeDesignation);
    }

    final collegeAdmin = profile.collegeAdminProfile;
    if (collegeAdmin != null && !collegeAdmin.isEmpty) {
      _add(rows, 'College designation', collegeAdmin.officeDesignation);
    }

    return rows;
  }

  static void _add(List<({String label, String value})> rows, String label, String value) {
    final String trimmed = value.trim();
    if (trimmed.isNotEmpty) rows.add((label: label, value: trimmed));
  }

  static void _addList(List<({String label, String value})> rows, String label, List<String> values) {
    final String joined = values.map((String e) => e.trim()).where((String e) => e.isNotEmpty).join(', ');
    if (joined.isNotEmpty) rows.add((label: label, value: joined));
  }
}
