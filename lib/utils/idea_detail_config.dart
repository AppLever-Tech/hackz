import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import 'role_visibility_helpers.dart';

class IdeaDetailConfig {
  const IdeaDetailConfig({
    required this.canViewIdeas,
    required this.canVerifyPayment,
    required this.canUploadPayment,
    required this.canEvaluate,
    required this.canViewSensitivePayment,
    required this.canEditTeam,
  });

  final bool canViewIdeas;
  final bool canVerifyPayment;
  final bool canUploadPayment;
  final bool canEvaluate;
  final bool canViewSensitivePayment;
  final bool canEditTeam;
}

class IdeaDetailRoleConfig {
  IdeaDetailRoleConfig._();

  static IdeaDetailConfig configFor(UserModel user) {
    final role = UserRole.fromCode(user.role);
    final canViewIdeas = RoleVisibilityHelpers.canViewIdeas(role);
    switch (role) {
      case UserRole.student:
        return IdeaDetailConfig(
          canViewIdeas: canViewIdeas,
          canVerifyPayment: false,
          canUploadPayment: true,
          canEvaluate: false,
          canViewSensitivePayment: true,
          canEditTeam: false,
        );
      case UserRole.faculty:
        return IdeaDetailConfig(
          canViewIdeas: canViewIdeas,
          canVerifyPayment: false,
          canUploadPayment: true,
          canEvaluate: false,
          canViewSensitivePayment: true,
          canEditTeam: true,
        );
      case UserRole.coordinator:
        return const IdeaDetailConfig(
          canViewIdeas: false,
          canVerifyPayment: false,
          canUploadPayment: false,
          canEvaluate: false,
          canViewSensitivePayment: false,
          canEditTeam: false,
        );
      case UserRole.judge:
        return IdeaDetailConfig(
          canViewIdeas: canViewIdeas,
          canVerifyPayment: false,
          canUploadPayment: false,
          canEvaluate: true,
          canViewSensitivePayment: false,
          canEditTeam: false,
        );
      case UserRole.departmentAdmin:
      case UserRole.collegeAdmin:
      case UserRole.sysAdmin:
        return IdeaDetailConfig(
          canViewIdeas: canViewIdeas,
          canVerifyPayment: false,
          canUploadPayment: false,
          canEvaluate: false,
          canViewSensitivePayment: true,
          canEditTeam: false,
        );
    }
  }
}
