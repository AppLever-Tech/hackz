import 'college_admin_profile.dart';
import 'department_admin_profile.dart';
import 'judge_profile.dart';
import 'professional_profile.dart';
import 'team_member_profile.dart';

/// Role-specific profile sections stored under `profile` on hkzUsers (not in identity fields).
class UserProfile {
  const UserProfile({
    this.professionalProfile,
    this.teamMemberProfile,
    this.judgeProfile,
    this.departmentAdminProfile,
    this.collegeAdminProfile,
  });

  final ProfessionalProfile? professionalProfile;
  final TeamMemberProfile? teamMemberProfile;
  final JudgeProfile? judgeProfile;
  final DepartmentAdminProfile? departmentAdminProfile;
  final CollegeAdminProfile? collegeAdminProfile;

  bool get isEmpty =>
      (professionalProfile == null || professionalProfile!.isEmpty) &&
      (teamMemberProfile == null || teamMemberProfile!.isEmpty) &&
      (judgeProfile == null || judgeProfile!.isEmpty) &&
      (departmentAdminProfile == null || departmentAdminProfile!.isEmpty) &&
      (collegeAdminProfile == null || collegeAdminProfile!.isEmpty);

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    if (professionalProfile != null && !professionalProfile!.isEmpty) {
      map['professionalProfile'] = professionalProfile!.toMap();
    }
    if (teamMemberProfile != null && !teamMemberProfile!.isEmpty) {
      map['studentProfile'] = teamMemberProfile!.toMap();
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
    TeamMemberProfile? teamMember;
    final dynamic teamMemberRaw = map['studentProfile'];
    if (teamMemberRaw is Map<String, dynamic>) {
      teamMember = TeamMemberProfile.fromMap(teamMemberRaw);
      if (teamMember.isEmpty) teamMember = null;
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
      teamMemberProfile: teamMember,
      judgeProfile: judge,
      departmentAdminProfile: deptAdmin,
      collegeAdminProfile: collegeAdmin,
    );
  }

  UserProfile copyWith({
    ProfessionalProfile? professionalProfile,
    TeamMemberProfile? teamMemberProfile,
    JudgeProfile? judgeProfile,
    DepartmentAdminProfile? departmentAdminProfile,
    CollegeAdminProfile? collegeAdminProfile,
  }) {
    return UserProfile(
      professionalProfile: professionalProfile ?? this.professionalProfile,
      teamMemberProfile: teamMemberProfile ?? this.teamMemberProfile,
      judgeProfile: judgeProfile ?? this.judgeProfile,
      departmentAdminProfile: departmentAdminProfile ?? this.departmentAdminProfile,
      collegeAdminProfile: collegeAdminProfile ?? this.collegeAdminProfile,
    );
  }
}
