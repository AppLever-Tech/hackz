import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../features/user/models/enums/user_role.dart';
import '../../features/user/models/user_model.dart';
import '../../features/idea/services/idea_role_config.dart';
import '../../features/problems/services/problem_role_config.dart';
import '../../utils/student_dashboard_service.dart';
import '../../utils/common_helpers.dart';
import '../../features/team/widgets/student_team_overview_card.dart';
import '../../core/responsive/responsive_helper.dart';
import '../../core/responsive/responsive_columns.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../core/responsive/responsive_metric_grid.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../../features/leaderboard/screens/leaderboard_showcase_screen.dart';
import '../../features/idea/screens/ideas_list_screen.dart';
import '../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../widgets/common/dashboard_card/dashboard_card_layout.dart';
import '../../widgets/common/entity_card_pills.dart';
import '../../widgets/common/form_value_row.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/widgets/common/context_pill.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return ProblemStatementsTableScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.student, user),
          );
        }
        if (selectedMenuIndex == 2) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.student, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        return _StudentDashboardHome(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}

class _StudentDashboardHome extends StatefulWidget {
  const _StudentDashboardHome({super.key, required this.user});

  final UserModel user;

  @override
  State<_StudentDashboardHome> createState() => _StudentDashboardHomeState();
}

class _StudentDashboardHomeState extends State<_StudentDashboardHome> {
  static const double _kDashboardIconSize = 18;

  late Future<StudentDashboardVm> _future;
  final StudentDashboardService _service = StudentDashboardService();

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StudentDashboardVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load student dashboard: ${snapshot.error}');
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

  Widget _buildSummaryCards(StudentDashboardVm vm) {
    final inProgressIdeas = vm.pendingIdeas + vm.submittedIdeas + vm.reviewIdeas;
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
              tooltip: 'In Progress (Pending + Submitted + Under Review)',
              value: '$inProgressIdeas',
              color: StatusStyles.submitted,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusShortlisted,
              tooltip: 'Shortlisted',
              value: '${vm.approvedIdeas}',
              color: StatusStyles.approved,
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusRejected,
              tooltip: 'Rejected',
              value: '${vm.rejectedIdeas}',
              color: StatusStyles.rejected,
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
              icon: AppIcons.statusRejected,
              tooltip: 'Rejected',
              value: '${vm.rejectedPayments}',
              color: const Color(0xFFB93838),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsAndTeamRow(StudentDashboardVm vm) {
    return DashboardPairRow(
      height: DashboardLayoutTokens.studentDetailsRowHeight,
      pair: ResponsivePair(
        spacing: ResponsiveHelper.dashboardSectionGap(context),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        first: _buildMyDetailsCard(vm),
        second: StudentTeamOverviewCard(vm: vm, compact: true),
      ),
    );
  }

  Widget _buildMyDetailsCard(StudentDashboardVm vm) {
    final Widget details = _buildStudentDetailsContent(vm);
    return SectionContainer(
      child: DashboardBoundedBody(
        headers: const <Widget>[
          DashboardCardTitle(title: 'My Details', icon: AppIcons.student),
          SizedBox(height: DashboardCardTitleStyle.headerSpacing),
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

  Widget _buildIdeasAndActivityRow(StudentDashboardVm vm) {
    return DashboardPairRow(
      height: DashboardLayoutTokens.pairRowList,
      pair: ResponsivePair(
        spacing: ResponsiveHelper.dashboardSectionGap(context),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        first: _StudentMyIdeasCard(vm: vm),
        second: _buildRecentActivity(vm),
      ),
    );
  }

  Widget _buildStudentDetailsContent(StudentDashboardVm vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        FormValueRow(
          labelWidth: EntityCardStyles.labelWidth,
          label: 'Student',
          child: _userWorkspaceValue(
            name: vm.studentName,
            userId: vm.studentId,
            icon: AppIcons.student,
          ),
        ),
        const SizedBox(height: 4),
        FormValueRow(
          labelWidth: EntityCardStyles.labelWidth,
          label: 'Mentor',
          child: _userWorkspaceValue(
            name: vm.mentorName,
            userId: vm.mentorId,
            icon: AppIcons.faculty,
          ),
        ),
        const SizedBox(height: 4),
        FormValueRow(
          labelWidth: EntityCardStyles.labelWidth,
          label: 'Dept Admin',
          child: _userWorkspaceValue(
            name: vm.departmentAdminName,
            userId: vm.departmentAdminId,
            icon: AppIcons.departments,
          ),
        ),
        const SizedBox(height: 4),
        FormValueRow(
          labelWidth: EntityCardStyles.labelWidth,
          label: 'College Admin',
          child: _userWorkspaceValue(
            name: vm.collegeAdminName,
            userId: vm.collegeAdminId,
            icon: AppIcons.organizations,
          ),
        ),
      ],
    );
  }

  Widget _userWorkspaceValue({
    required String name,
    required String userId,
    required IconData icon,
  }) {
    final String display = name.trim().isEmpty ? '—' : name.trim();
    if (userId.trim().isEmpty) {
      return EntityCardPills.plainValue(display);
    }
    return EntityCardPills.workspace(
      display,
      ContextPillSemantic.user,
      () => WorkspaceNavigator.openUser(context, userId),
      fullWidth: true,
      icon: icon,
    );
  }

  Widget _buildRecentActivity(StudentDashboardVm vm) {
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

  Widget _activityRow(StudentActivityItem activity) {
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

class _StudentMyIdeasCard extends StatelessWidget {
  const _StudentMyIdeasCard({required this.vm});

  final StudentDashboardVm vm;

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

  Widget _ideaPreviewRow(BuildContext context, StudentIdeaItem item) {
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
          size: _StudentDashboardHomeState._kDashboardIconSize,
        ),
      ],
    );
  }
}
