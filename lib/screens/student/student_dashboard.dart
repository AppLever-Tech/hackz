import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../../utils/student_dashboard_service.dart';
import '../../utils/common_helpers.dart';
import '../../widgets/common/idea_status_distribution_donut.dart';
import '../../widgets/student_team_overview_card.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/responsive/adaptive_dashboard_panel.dart';
import '../../widgets/responsive/responsive_columns.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import '../../widgets/common/entity_card_pills.dart';
import '../../widgets/common/form_value_row.dart';
import '../../workspace/workspace.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.student, user),
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.student, user),
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
  static const double _kDetailsChartHeight = DashboardCardTitleStyle.compactBodyHeight;

  late Future<StudentDashboardVm> _future;
  final StudentDashboardService _service = StudentDashboardService();
  int _activityLimit = 8;
  double? _teamOverviewHeight;

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
              _buildStatusAndDetailsRow(vm),
              SizedBox(height: gap),
              _buildTeamOverviewAndActivityRow(vm),
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
              icon: AppIcons.statusApproved,
              tooltip: 'Approved',
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
              icon: AppIcons.statusSubmitted,
              tooltip: 'Pending',
              value: '${vm.pendingPayments}',
              color: const Color(0xFFB56A11),
            ),
            DashboardMetricChipSegment(
              icon: AppIcons.statusApproved,
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

  Widget _buildStatusAndDetailsRow(StudentDashboardVm vm) {
    return ResponsivePair(
      spacing: ResponsiveHelper.dashboardSectionGap(context),
      first: ChartCard(
        title: 'Student Details',
        icon: AppIcons.student,
        child: SizedBox(
          height: _kDetailsChartHeight,
          child: _buildStudentDetailsContent(vm),
        ),
      ),
      second: ChartCard(
        title: 'Idea Status Distribution',
        icon: AppIcons.ideas,
        child: ResponsiveChartBox(
          desktopHeight: _kDetailsChartHeight,
          child: IdeaStatusDistributionDonut(
            pending: vm.pendingIdeas,
            submitted: vm.submittedIdeas,
            underReview: vm.reviewIdeas,
            evaluated: vm.evaluatedIdeas,
            approved: vm.approvedIdeas,
            rejected: vm.rejectedIdeas,
          ),
        ),
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
        const SizedBox(height: 6),
        FormValueRow(
          labelWidth: EntityCardStyles.labelWidth,
          label: 'Mentor',
          child: _userWorkspaceValue(
            name: vm.mentorName,
            userId: vm.mentorId,
            icon: AppIcons.faculty,
          ),
        ),
        const SizedBox(height: 6),
        FormValueRow(
          labelWidth: EntityCardStyles.labelWidth,
          label: 'Dept Admin',
          child: _userWorkspaceValue(
            name: vm.departmentAdminName,
            userId: vm.departmentAdminId,
            icon: AppIcons.departments,
          ),
        ),
        const SizedBox(height: 6),
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

  Widget _buildTeamOverviewAndActivityRow(StudentDashboardVm vm) {
    final double gap = ResponsiveHelper.dashboardSectionGap(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool sideBySide = constraints.maxWidth >= ResponsiveBreakpoints.tablet;
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StudentTeamOverviewCard(vm: vm),
              SizedBox(height: gap),
              _buildRecentActivity(vm),
            ],
          );
        }

        final double activityHeight = _teamOverviewHeight ?? 200;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _ReportChildHeight(
                onHeight: (double height) {
                  if (_teamOverviewHeight != height) {
                    setState(() => _teamOverviewHeight = height);
                  }
                },
                child: StudentTeamOverviewCard(vm: vm),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: SizedBox(
                height: activityHeight,
                child: _buildRecentActivity(vm, height: activityHeight),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity(StudentDashboardVm vm, {double? height}) {
    final visible = vm.activities.take(_activityLimit).toList(growable: false);
    final Widget activityBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (visible.isEmpty)
          const Text('No recent activity.')
        else
          ...visible.map(
            (StudentActivityItem a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(a.icon, size: 18, color: const Color(0xFF4B5AA9)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a.text)),
                  Text(
                    _formatDate(a.at),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
                  ),
                ],
              ),
            ),
          ),
        if (_activityLimit < vm.activities.length)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _activityLimit += 8),
              child: const Text('Load More'),
            ),
          ),
      ],
    );

    const Widget header = DashboardCardTitle(title: 'Recent Activity', icon: AppIcons.clock);

    if (height != null) {
      return SectionContainer(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              header,
              const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
              Expanded(
                child: SingleChildScrollView(
                  child: activityBody,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          header,
          const SizedBox(height: DashboardCardTitleStyle.headerSpacing),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: activityBody,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return formatDateTime(date);
  }
}

/// Reports [child] layout height after paint (safe with [LayoutBuilder] siblings).
class _ReportChildHeight extends StatefulWidget {
  const _ReportChildHeight({
    required this.child,
    required this.onHeight,
  });

  final Widget child;
  final ValueChanged<double> onHeight;

  @override
  State<_ReportChildHeight> createState() => _ReportChildHeightState();
}

class _ReportChildHeightState extends State<_ReportChildHeight> {
  final GlobalKey _key = GlobalKey();
  double? _lastHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_reportHeight);
  }

  @override
  void didUpdateWidget(covariant _ReportChildHeight oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_reportHeight);
  }

  void _reportHeight(Duration _) {
    final RenderBox? box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final double height = box.size.height;
    if (_lastHeight == height) return;
    _lastHeight = height;
    widget.onHeight(height);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

