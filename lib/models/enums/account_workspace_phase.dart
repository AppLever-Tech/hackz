import 'user_status.dart';

/// Onboarding / gate states for [AccountStatusWorkspace] (broader than [UserStatus] alone).
enum AccountWorkspacePhase {
  pendingApproval,
  approved,
  rejected,
  invalidAccessCode,
  suspended,
}

extension AccountWorkspacePhaseMapper on UserStatus {
  AccountWorkspacePhase get toWorkspacePhase {
    switch (this) {
      case UserStatus.active:
        return AccountWorkspacePhase.approved;
      case UserStatus.pendingApproval:
        return AccountWorkspacePhase.pendingApproval;
      case UserStatus.rejected:
        return AccountWorkspacePhase.rejected;
      case UserStatus.suspended:
        return AccountWorkspacePhase.suspended;
    }
  }
}
