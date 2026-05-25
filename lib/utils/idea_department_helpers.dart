import '../models/department_model.dart';
import '../models/idea_model.dart';

/// Centralized innovation vs payment department resolution for ideas.
abstract final class IdeaDepartmentHelpers {
  static String teamDeptFromMap(Map<String, dynamic> map) {
    return DepartmentModel.resolveCode((map[IdeaModel.fieldTeamDepartmentCode] as String?) ?? '');
  }

  static String problemDeptFromMap(Map<String, dynamic> map) {
    return DepartmentModel.resolveCode((map[IdeaModel.fieldProblemDepartmentCode] as String?) ?? '');
  }

  static bool matchesTeamDept(Map<String, dynamic> map, String departmentCode) {
    final target = DepartmentModel.resolveCode(departmentCode);
    if (target.isEmpty) return true;
    return teamDeptFromMap(map) == target;
  }

  static bool matchesProblemDept(Map<String, dynamic> map, String departmentCode) {
    final target = DepartmentModel.resolveCode(departmentCode);
    if (target.isEmpty) return true;
    return problemDeptFromMap(map) == target;
  }

  static bool ideaMatchesTeamDept(IdeaModel idea, String departmentCode) {
    final target = DepartmentModel.resolveCode(departmentCode);
    if (target.isEmpty) return true;
    return DepartmentModel.resolveCode(idea.teamDepartmentCode) == target;
  }

  static bool ideaMatchesProblemDept(IdeaModel idea, String departmentCode) {
    final target = DepartmentModel.resolveCode(departmentCode);
    if (target.isEmpty) return true;
    return DepartmentModel.resolveCode(idea.problemDepartmentCode) == target;
  }
}
