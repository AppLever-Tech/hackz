import '../models/enums/user_role.dart';
import '../models/user_model.dart';

class IdeaDetailConfig {
  const IdeaDetailConfig({
    required this.canVerifyPayment,
    required this.canUploadPayment,
    required this.canEvaluate,
    required this.canViewSensitivePayment,
    required this.canEditTeam,
  });

  final bool canVerifyPayment;
  final bool canUploadPayment;
  final bool canEvaluate;
  final bool canViewSensitivePayment;
  final bool canEditTeam;
}

class IdeaDetailRoleConfig {
  IdeaDetailRoleConfig._();

  static IdeaDetailConfig configFor(UserModel user) {
    switch (UserRole.fromCode(user.role)) {
      case UserRole.student:
        return const IdeaDetailConfig(
          canVerifyPayment: false,
          canUploadPayment: true,
          canEvaluate: false,
          canViewSensitivePayment: true,
          canEditTeam: false,
        );
      case UserRole.faculty:
        return const IdeaDetailConfig(
          canVerifyPayment: false,
          canUploadPayment: true,
          canEvaluate: false,
          canViewSensitivePayment: true,
          canEditTeam: true,
        );
      case UserRole.coordinator:
        return const IdeaDetailConfig(
          canVerifyPayment: true,
          canUploadPayment: false,
          canEvaluate: false,
          canViewSensitivePayment: true,
          canEditTeam: false,
        );
      case UserRole.judge:
        return const IdeaDetailConfig(
          canVerifyPayment: false,
          canUploadPayment: false,
          canEvaluate: true,
          canViewSensitivePayment: false,
          canEditTeam: false,
        );
      case UserRole.departmentAdmin:
      case UserRole.collegeAdmin:
      case UserRole.sysAdmin:
        return const IdeaDetailConfig(
          canVerifyPayment: false,
          canUploadPayment: false,
          canEvaluate: false,
          canViewSensitivePayment: true,
          canEditTeam: false,
        );
    }
  }
}
