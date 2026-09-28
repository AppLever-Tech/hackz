import '../../idea/models/enums/idea_status.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';

abstract final class IdeaAnalysisAccess {
  IdeaAnalysisAccess._();

  static bool canManageAnalysis(UserModel user) {
    return user.hasRoleCode(UserRole.collegeAdmin.code) ||
        user.hasRoleCode(UserRole.orgAdmin.code) ||
        user.hasRoleCode(UserRole.departmentAdmin.code);
  }

  static bool ideaEligibleForAnalysis(IdeaStatus status) {
    return status == IdeaStatus.submitted;
  }
}
