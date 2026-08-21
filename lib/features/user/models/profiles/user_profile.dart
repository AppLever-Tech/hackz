import 'college_admin_profile.dart';
import 'department_admin_profile.dart';
import 'judge_profile.dart';
import 'professional_profile.dart';
import 'student_profile.dart';

/// Role-specific profile sections stored under `profile` on hkzUsers (not in identity fields).
class UserProfile {
  const UserProfile({
    this.professionalProfile,
    this.studentProfile,
    this.judgeProfile,
    this.departmentAdminProfile,
    this.collegeAdminProfile,
  });

  final ProfessionalProfile? professionalProfile;
  final StudentProfile? studentProfile;
  final JudgeProfile? judgeProfile;
  final DepartmentAdminProfile? departmentAdminProfile;
  final CollegeAdminProfile? collegeAdminProfile;

  bool get isEmpty =>
      (professionalProfile == null || professionalProfile!.isEmpty) &&
      (studentProfile == null || studentProfile!.isEmpty) &&
      (judgeProfile == null || judgeProfile!.isEmpty) &&
      (departmentAdminProfile == null || departmentAdminProfile!.isEmpty) &&
      (collegeAdminProfile == null || collegeAdminProfile!.isEmpty);

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (professionalProfile != null && !professionalProfile!.isEmpty) {
      map['professionalProfile'] = professionalProfile!.toMap();
    }
    if (studentProfile != null && !studentProfile!.isEmpty) {
      map['studentProfile'] = studentProfile!.toMap();
    }
    if (judgeProfile != null && !judgeProfile!.isEmpty) {
      map['judgeProfile'] = judgeProfile!.toMap();
    }
    if (departmentAdminProfile != null && !departmentAdminProfile!.isEmpty) {
      map['departmentAdminProfile'] = departmentAdminProfile!.toMap();
    }
    if (collegeAdminProfile != null && !collegeAdminProfile!.isEmpty) {
      map['collegeAdminProfile'] = collegeAdminProfile!.toMap();
    }
    return map;
  }

  factory UserProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const UserProfile();
    ProfessionalProfile? professional;
    final dynamic profRaw = map['professionalProfile'];
    if (profRaw is Map<String, dynamic>) {
      professional = ProfessionalProfile.fromMap(profRaw);
      if (professional.isEmpty) professional = null;
    }
    StudentProfile? student;
    final dynamic studentRaw = map['studentProfile'];
    if (studentRaw is Map<String, dynamic>) {
      student = StudentProfile.fromMap(studentRaw);
      if (student.isEmpty) student = null;
    }
    JudgeProfile? judge;
    final dynamic judgeRaw = map['judgeProfile'];
    if (judgeRaw is Map<String, dynamic>) {
      judge = JudgeProfile.fromMap(judgeRaw);
      if (judge.isEmpty) judge = null;
    }
    DepartmentAdminProfile? deptAdmin;
    final dynamic deptAdminRaw = map['departmentAdminProfile'];
    if (deptAdminRaw is Map<String, dynamic>) {
      deptAdmin = DepartmentAdminProfile.fromMap(deptAdminRaw);
      if (deptAdmin.isEmpty) deptAdmin = null;
    }
    CollegeAdminProfile? collegeAdmin;
    final dynamic collegeAdminRaw = map['collegeAdminProfile'];
    if (collegeAdminRaw is Map<String, dynamic>) {
      collegeAdmin = CollegeAdminProfile.fromMap(collegeAdminRaw);
      if (collegeAdmin.isEmpty) collegeAdmin = null;
    }
    return UserProfile(
      professionalProfile: professional,
      studentProfile: student,
      judgeProfile: judge,
      departmentAdminProfile: deptAdmin,
      collegeAdminProfile: collegeAdmin,
    );
  }

  UserProfile copyWith({
    ProfessionalProfile? professionalProfile,
    StudentProfile? studentProfile,
    JudgeProfile? judgeProfile,
    DepartmentAdminProfile? departmentAdminProfile,
    CollegeAdminProfile? collegeAdminProfile,
  }) {
    return UserProfile(
      professionalProfile: professionalProfile ?? this.professionalProfile,
      studentProfile: studentProfile ?? this.studentProfile,
      judgeProfile: judgeProfile ?? this.judgeProfile,
      departmentAdminProfile: departmentAdminProfile ?? this.departmentAdminProfile,
      collegeAdminProfile: collegeAdminProfile ?? this.collegeAdminProfile,
    );
  }
}
