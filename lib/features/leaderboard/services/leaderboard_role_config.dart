import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';

enum LeaderboardShowcaseTab {
  teams,
  departments,
  ideas,
}

/// Role-scoped visibility for Innovation Leaderboard Showcase (config-driven).
class LeaderboardRoleConfig {
  const LeaderboardRoleConfig({
    required this.visibleTabs,
    required this.scopeOrgId,
    required this.scopeDepartmentCode,
    required this.platformWide,
    required this.judgeEvaluationAnalyticsOnly,
    required this.teamMemberTeamId,
  });

  /// Tabs shown in the tab bar (subset allowed per role).
  final Set<LeaderboardShowcaseTab> visibleTabs;

  /// Non-empty for org-scoped roles; ignored when [platformWide].
  final String scopeOrgId;

  /// Optional department filter (normalized uppercase code).
  final String? scopeDepartmentCode;

  /// SysAdmin: aggregate across organizations.
  final bool platformWide;

  /// Judge: analytics / distributions only — no competitive final rankings UI.
  final bool judgeEvaluationAnalyticsOnly;

  /// Team Member: optional team scope for team tab emphasis.
  final String? teamMemberTeamId;

  factory LeaderboardRoleConfig.forUser(UserModel user) {
    final role = UserRole.fromCode(user.role);
    final org = user.orgId.trim();
    final dept = user.departmentCode.trim().isEmpty ? null : user.departmentCode.trim().toUpperCase();

    switch (role) {
      case UserRole.teamMember:
        return LeaderboardRoleConfig(
          visibleTabs: {
            LeaderboardShowcaseTab.teams,
            LeaderboardShowcaseTab.departments,
          },
          scopeOrgId: org,
          scopeDepartmentCode: dept,
          platformWide: false,
          judgeEvaluationAnalyticsOnly: false,
          teamMemberTeamId: user.teamId?.trim().isEmpty ?? true ? null : user.teamId!.trim(),
        );
      case UserRole.departmentAdmin:
        return LeaderboardRoleConfig(
          visibleTabs: {
            LeaderboardShowcaseTab.departments,
            LeaderboardShowcaseTab.teams,
            LeaderboardShowcaseTab.ideas,
          },
          scopeOrgId: org,
          scopeDepartmentCode: dept,
          platformWide: false,
          judgeEvaluationAnalyticsOnly: false,
          teamMemberTeamId: null,
        );
      case UserRole.collegeAdmin:
        return LeaderboardRoleConfig(
          visibleTabs: LeaderboardShowcaseTab.values.toSet(),
          scopeOrgId: org,
          scopeDepartmentCode: null,
          platformWide: false,
          judgeEvaluationAnalyticsOnly: false,
          teamMemberTeamId: null,
        );
      case UserRole.coordinator:
        return LeaderboardRoleConfig(
          visibleTabs: {
            LeaderboardShowcaseTab.teams,
            LeaderboardShowcaseTab.departments,
          },
          scopeOrgId: org,
          scopeDepartmentCode: dept,
          platformWide: false,
          judgeEvaluationAnalyticsOnly: false,
          teamMemberTeamId: null,
        );
      case UserRole.judge:
        return LeaderboardRoleConfig(
          visibleTabs: {
            LeaderboardShowcaseTab.ideas,
          },
          scopeOrgId: org,
          scopeDepartmentCode: null,
          platformWide: false,
          judgeEvaluationAnalyticsOnly: true,
          teamMemberTeamId: null,
        );
      case UserRole.sysAdmin:
        return LeaderboardRoleConfig(
          visibleTabs: LeaderboardShowcaseTab.values.toSet(),
          scopeOrgId: '',
          scopeDepartmentCode: null,
          platformWide: true,
          judgeEvaluationAnalyticsOnly: false,
          teamMemberTeamId: null,
        );
    }
  }
}
