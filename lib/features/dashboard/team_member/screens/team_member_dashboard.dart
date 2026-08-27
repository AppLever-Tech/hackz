import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/status_styles.dart';
import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/idea/services/idea_role_config.dart';
import '../../../../features/problems/services/problem_role_config.dart';
import '../services/team_member_dashboard_service.dart';
import '../../../../utils/common_helpers.dart';
import '../../../../features/team/widgets/team_overview_card.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/responsive/responsive_columns.dart';
import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../../core/responsive/responsive_metric_grid.dart';
import '../../chrome/dashboard_components.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../../../features/idea/screens/ideas_list_screen.dart';
import '../../../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../../../features/team/screens/teams_screen.dart';
import '../../../../features/team/services/team_service.dart';
import '../../../../features/payment/screens/payments_screen.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../../../../core/ui/common/entity_card_pills.dart';
import '../../../../core/ui/common/form_value_row.dart';
import '../../../../core/ui/common/context_pill.dart';
import '../../../../core/ui/common/context_pill_theme.dart';
import '../../../../core/workspace/user_list_identity_lead.dart';
import '../../../../core/workspace/user_workspace_avatar.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

class TeamMemberDashboard extends StatefulWidget {
  const TeamMemberDashboard({super.key, required this.user});

  final UserModel user;

  @override
  State<TeamMemberDashboard> createState() => _TeamMemberDashboardState();
}

class _TeamMemberDashboardState extends State<TeamMemberDashboard> {
  late Future<bool> _isTeamLeaderFuture;

  @override
  void initState() {
    super.initState();
    _isTeamLeaderFuture = TeamService.userLeadsAnyTeam(widget.user.userId);
  }

  List<DashboardMenuItem> _menus(bool isTeamLeader) {
    return <DashboardMenuItem>[
      const DashboardMenuItem(label: 'Dashboard', icon: AppIcons.dashboard),
      if (isTeamLeader) const DashboardMenuItem(label: 'My Teams', icon: AppIcons.users),
      if (isTeamLeader)
        const DashboardMenuItem(label: 'My Ideas', icon: AppIcons.submissions)
      else
        const DashboardMenuItem(label: 'Ideas', icon: AppIcons.ideas),
      const DashboardMenuItem(label: 'Problems', icon: AppIcons.problems),
      if (isTeamLeader) const DashboardMenuItem(label: 'Payments', icon: AppIcons.payments),
    ];
  }

  Widget _bodyForMenu({
    required String label,
    required int refreshToken,
    required bool isTeamLeader,
  }) {
    final UserModel user = widget.user;
    switch (label) {
      case 'My Teams':
        return TeamsScreen(key: ValueKey<int>(refreshToken), user: user);
      case 'Problems':
        return ProblemStatementsTableScreen(
          key: ValueKey<int>(refreshToken),
          currentUser: user,
          config: ProblemRoleConfig.configFor(UserRole.teamMember, user, teamLeader: isTeamLeader),
        );
      case 'Ideas':
        return IdeasListScreen(
          key: ValueKey<int>(refreshToken),
          currentUser: user,
          config: IdeaRoleConfig.configFor(UserRole.teamMember, user),
        );
      case 'My Ideas':
        return IdeasListScreen(
          key: ValueKey<int>(refreshToken),
          currentUser: user,
          config: IdeaRoleConfig.configFor(UserRole.teamMember, user, teamLeader: true),
        );
      case 'Payments':
        return PaymentsScreen(
          key: ValueKey<int>(refreshToken),
          user: user,
          ledTeamsOnly: true,
        );
      default:
        return _TeamMemberDashboardHome(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isTeamLeaderFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        final bool isTeamLeader = snapshot.data ?? false;
        final List<DashboardMenuItem> menus = _menus(isTeamLeader);
        return DashboardPageTemplate(
          user: widget.user,
          primaryMenusOverride: menus,
          bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
            final String label =
                selectedMenuIndex >= 0 && selectedMenuIndex < menus.length ? menus[selectedMenuIndex].label : 'Dashboard';
            return _bodyForMenu(
              label: label,
              refreshToken: refreshToken,
              isTeamLeader: isTeamLeader,
            );
          },
        );
      },
    );
  }
}

class _TeamMemberDashboardHome extends StatefulWidget {
  const _TeamMemberDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_TeamMemberDashboardHome> createState() => _TeamMemberDashboardHomeState();
}

class _TeamMemberDashboardHomeState extends State<_TeamMemberDashboardHome> {
  static const double _kDashboardIconSize = 18;
  static const double _detailsLabelWidth = 96;
  static const double _detailsLabelGap = EntityCardStyles.labelGap;
  static const Alignment _detailsLabelAlignment = Alignment.centerLeft;

  late Future<TeamMemberDashboardVm> _future;
  final TeamMemberDashboardService _service = TeamMemberDashboardService();

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeamMemberDashboardVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load dashboard: ${snapshot.error}');
        }
        final vm = snapshot.data!;
        final gap = ResponsiveHelper.dashboardSectionGap(context);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSummaryCards(vm),
              SizedBox(height: gap),
              _buildDetailsAndTeamRow(vm),
              SizedBox(height: gap),
              _buildIdeasAndActivityRow(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(TeamMemberDashboardVm vm) {
    final inProgressIdeas = vm.pendingIdeas + vm.submittedIdeas;
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Members • ${vm.team.teamName.isEmpty ? 'No Team' : vm.team.teamName}',
          value: '${vm.teamMemberCount}',
          color: const Color(0xFF4A67FF),
          icon: AppIcons.teams,
        ),
        DashboardMetricChipData.withSegments(
          label: 'Ideas',
          color: const Color(0xFF7C3AED),
          icon: AppIcons.ideas,
          segments: <DashboardMetricChipSegment>[
            DashboardMetricChipSegment(
              icon: AppIcons.statusSubmitted,
              tooltip: 'In Progress (Pending + Submitted)',
              value: '$inProgressIdeas',
              color: StatusStyles.submitted,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusEvaluated,
              tooltip: 'Scored',
              value: '${vm.approvedIdeas}',
              color: StatusStyles.evaluated,
            ),
          ],
        ),
        DashboardMetricChipData.ratio(
          label: 'Avg / Highest Score',
          primary: vm.avgScore?.toStringAsFixed(1) ?? '-',
          secondary: vm.highestScore?.toStringAsFixed(1) ?? '-',
          color: const Color(0xFF059669),
          icon: AppIcons.scoring,
        ),
        DashboardMetricChipData.withSegments(
          label: 'Payments',
          color: const Color(0xFFEA580C),
          icon: AppIcons.payments,
          segments: <DashboardMetricChipSegment>[
            DashboardMetricChipSegment(
              icon: AppIcons.workflowPendingReview,
              tooltip: 'Pending',
              value: '${vm.pendingPayments}',
              color: const Color(0xFFB56A11),
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.workflowApproved,
              tooltip: 'Verified',
              value: '${vm.verifiedPayments}',
              color: const Color(0xFF177C50),
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.workflowRejected,
              tooltip: 'Rejected',
              value: '${vm.rejectedPayments}',
              color: const Color(0xFFB93838),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsAndTeamRow(TeamMemberDashboardVm vm) {
    return DashboardPairRow(
      height: DashboardLayoutTokens.studentDetailsRowHeight,
      pair: ResponsivePair(
        spacing: ResponsiveHelper.dashboardSectionGap(context),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        first: _buildMyDetailsCard(vm),
        second: TeamOverviewCard(vm: vm, compact: true),
      ),
    );
  }

  Widget _buildMyDetailsCard(TeamMemberDashboardVm vm) {
    final Widget details = _buildTeamMemberDetailsContent(vm);
    final String titleName = vm.teamMemberName.trim().isEmpty ? 'Team Member' : vm.teamMemberName.trim();
    return SectionContainer(
      child: DashboardBoundedBody(
        headers: <Widget>[
          _buildMyDetailsHeader(titleName),
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
        ],
        bodyBuilder: ({required bool expandVertically}) {
          if (expandVertically) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: details,
            );
          }
          return details;
        },
      ),
    );
  }

  Widget _buildMyDetailsHeader(String teamMemberName) {
    final String userId = widget.user.userId.trim();
    return Row(
      children: <Widget>[
        Icon(AppIcons.teamMember, size: DashboardCardTitleStyle.iconSize, color: DashboardCardTitleStyle.iconColor),
        const SizedBox(width: DashboardCardTitleStyle.iconGap),
        const Text('My Details', style: DashboardCardTitleStyle.textStyle),
        const SizedBox(width: 10),
        UserWorkspaceAvatar(
          user: widget.user,
          radius: 12,
          onTap: userId.isEmpty ? () {} : () => WorkspaceNavigator.openUser(context, userId),
          enabled: userId.isNotEmpty,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teamMemberName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardCardTitleStyle.textStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildIdeasAndActivityRow(TeamMemberDashboardVm vm) {
    return DashboardPairRow(
      height: DashboardLayoutTokens.pairRowList,
      pair: ResponsivePair(
        spacing: ResponsiveHelper.dashboardSectionGap(context),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        first: _TeamMemberMyIdeasCard(vm: vm),
        second: _buildRecentActivity(vm),
      ),
    );
  }

  Widget _buildTeamMemberDetailsContent(TeamMemberDashboardVm vm) {
    final String department = vm.department.trim().isEmpty ? '—' : vm.department.trim();
    final String college = vm.organizationName.trim().isEmpty ? '—' : vm.organizationName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        FormValueRow(
          labelWidth: _detailsLabelWidth,
          labelGap: _detailsLabelGap,
          label: 'Dept Admin',
          labelIcon: AppIcons.departments,
          labelAlignment: _detailsLabelAlignment,
          child: _userIdentityLead(user: vm.departmentAdminUser, fallbackName: vm.departmentAdminName),
        ),
        const SizedBox(height: 8),
        FormValueRow(
          labelWidth: _detailsLabelWidth,
          labelGap: _detailsLabelGap,
          label: 'Department',
          labelIcon: AppIcons.departments,
          labelAlignment: _detailsLabelAlignment,
          child: EntityCardPills.plainValue(department),
        ),
        const SizedBox(height: 8),
        FormValueRow(
          labelWidth: _detailsLabelWidth,
          labelGap: _detailsLabelGap,
          label: 'College Admin',
          labelIcon: AppIcons.organizations,
          labelAlignment: _detailsLabelAlignment,
          child: _userIdentityLead(user: vm.collegeAdminUser, fallbackName: vm.collegeAdminName),
        ),
        const SizedBox(height: 8),
        FormValueRow(
          labelWidth: _detailsLabelWidth,
          labelGap: _detailsLabelGap,
          label: 'College',
          labelIcon: AppIcons.organizations,
          labelAlignment: _detailsLabelAlignment,
          child: EntityCardPills.plainValue(college),
        ),
      ],
    );
  }

  Widget _userIdentityLead({
    required UserModel? user,
    required String fallbackName,
  }) {
    final String display = fallbackName.trim().isEmpty || fallbackName.trim() == '-' ? '—' : fallbackName.trim();
    if (user == null || user.userId.trim().isEmpty) {
      return EntityCardPills.plainValue(display);
    }
    return UserListIdentityLead(
      user: user,
      avatarRadius: 12,
    );
  }

  Widget _buildRecentActivity(TeamMemberDashboardVm vm) {
    return SectionContainer(
      child: DashboardListCard(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        preset: DashboardListPreset.compact,
        headers: const <Widget>[
          DashboardCardTitle(title: 'Recent Activity', icon: AppIcons.clock),
          SizedBox(height: DashboardCardTitleStyle.headerSpacing),
        ],
        itemCount: vm.activities.length,
        empty: const Align(
          alignment: Alignment.topLeft,
          child: Text('No recent activity.'),
        ),
        itemBuilder: (BuildContext context, int index) => _activityRow(vm.activities[index]),
      ),
    );
  }

  Widget _activityRow(TeamMemberActivityItem activity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(activity.icon, size: _kDashboardIconSize, color: const Color(0xFF4B5AA9)),
        const SizedBox(width: 8),
        Expanded(child: Text(activity.text)),
        Text(
          _formatDate(activity.at),
          style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return formatDateTime(date);
  }
}

class _TeamMemberMyIdeasCard extends StatelessWidget {
  const _TeamMemberMyIdeasCard({required this.vm});

  final TeamMemberDashboardVm vm;

  @override
  Widget build(BuildContext context) {
    final int count = vm.ideaCards.length;
    return SectionContainer(
      child: DashboardListCard(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        preset: DashboardListPreset.compact,
        headers: <Widget>[
          DashboardIconCountHeader(title: 'My Ideas', icon: AppIcons.ideas, count: count),
          const SizedBox(height: DashboardLayoutTokens.iconCountHeaderGap),
        ],
        itemCount: count,
        empty: const Center(child: Text('-', style: TextStyle(color: Color(0xFF6E7394)))),
        itemBuilder: (BuildContext context, int index) => _ideaPreviewRow(context, vm.ideaCards[index]),
      ),
    );
  }

  Widget _ideaPreviewRow(BuildContext context, TeamMemberIdeaItem item) {
    final String title =
        item.idea.ideaTitle.trim().isEmpty ? 'Untitled Idea' : item.idea.ideaTitle.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: item.idea.ideaId.trim().isNotEmpty
              ? ContextPill(
                  label: title,
                  semantic: ContextPillSemantic.idea,
                  onTap: () => WorkspaceNavigator.openIdea(context, item.idea.ideaId),
                  compact: true,
                )
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(width: 8),
        StatusStyles.ideaStatusIcon(
          item.idea.status,
          size: _TeamMemberDashboardHomeState._kDashboardIconSize,
        ),
      ],
    );
  }
}
