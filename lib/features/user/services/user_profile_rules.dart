import '../models/enums/user_role.dart';
import '../models/profiles/college_admin_profile.dart';
import '../models/profiles/department_admin_profile.dart';
import '../models/profiles/faculty_profile.dart';
import '../models/profiles/judge_profile.dart';
import '../models/profiles/professional_profile.dart';
import '../models/profiles/student_profile.dart';
import '../models/profiles/user_profile.dart';

/// Determines which profile sections apply for a set of role codes.
abstract final class UserProfileRules {
  static bool needsProfessional(Set<String> roleCodes) {
    return roleCodes.contains(UserRole.faculty.code) || roleCodes.contains(UserRole.judge.code);
  }

  static bool needsStudent(Set<String> roleCodes) => roleCodes.contains(UserRole.student.code);

  static bool needsFaculty(Set<String> roleCodes) => roleCodes.contains(UserRole.faculty.code);

  static bool needsJudge(Set<String> roleCodes) => roleCodes.contains(UserRole.judge.code);

  static bool needsDepartmentAdmin(Set<String> roleCodes) =>
      roleCodes.contains(UserRole.departmentAdmin.code);

  static bool needsCollegeAdmin(Set<String> roleCodes) => roleCodes.contains(UserRole.collegeAdmin.code);

  static UserProfile buildProfile({
    required Set<String> roleCodes,
    ProfessionalProfile? professional,
    StudentProfile? student,
    FacultyProfile? faculty,
    JudgeProfile? judge,
    DepartmentAdminProfile? departmentAdmin,
    CollegeAdminProfile? collegeAdmin,
  }) {
    return UserProfile(
      professionalProfile: needsProfessional(roleCodes) ? professional : null,
      studentProfile: needsStudent(roleCodes) ? student : null,
      facultyProfile: needsFaculty(roleCodes) ? faculty : null,
      judgeProfile: needsJudge(roleCodes) ? judge : null,
      departmentAdminProfile: needsDepartmentAdmin(roleCodes) ? departmentAdmin : null,
      collegeAdminProfile: needsCollegeAdmin(roleCodes) ? collegeAdmin : null,
    );
  }
}
