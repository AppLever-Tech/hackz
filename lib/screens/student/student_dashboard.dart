import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/enums/user_role.dart';
import '../../models/idea_model.dart';
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
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';

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
  late Future<StudentDashboardVm> _future;
  final StudentDashboardService _service = StudentDashboardService();
  int _activityLimit = 8;

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
              StudentTeamOverviewCard(vm: vm),
              SizedBox(height: gap),
              _buildRecentActivity(vm),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(StudentDashboardVm vm) {
    final inProgressIdeas = vm.pendingIdeas + vm.submittedIdeas + vm.reviewIdeas;
    return ResponsiveMetricGrid(
      children: <Widget>[
        DashboardCountCard(
          value: '${vm.teamMemberCount}',
          label: 'Members • ${vm.team.teamName.isEmpty ? 'No Team' : vm.team.teamName}',
          icon: AppIcons.teams,
          iconBgColor: const Color(0xFFEAF2FF),
        ),
        DashboardIconMetricCard(
          metrics: <DashboardIconMetric>[
            DashboardIconMetric(
              icon: AppIcons.statusSubmitted,
              tooltip: 'In Progress (Pending + Submitted + Under Review)',
              count: '$inProgressIdeas',
              color: StatusStyles.submitted,
            ),
            DashboardIconMetric(
              icon: AppIcons.statusApproved,
              tooltip: 'Approved',
              count: '${vm.approvedIdeas}',
              color: StatusStyles.approved,
            ),
            DashboardIconMetric(
              icon: AppIcons.statusRejected,
              tooltip: 'Rejected',
              count: '${vm.rejectedIdeas}',
              color: StatusStyles.rejected,
            ),
          ],
          label: 'Ideas',
          icon: AppIcons.ideas,
          iconBgColor: const Color(0xFFF2EDFF),
        ),
        DashboardCountCard(
          value: vm.avgScore?.toStringAsFixed(1) ?? '-',
          secondaryValue: vm.highestScore?.toStringAsFixed(1) ?? '-',
          label: 'Avg / Highest Score',
          icon: AppIcons.scoring,
          iconBgColor: const Color(0xFFE8FAF1),
        ),
        DashboardIconMetricCard(
          metrics: <DashboardIconMetric>[
            DashboardIconMetric(
              icon: AppIcons.statusSubmitted,
              tooltip: 'Pending',
              count: '${vm.pendingPayments}',
              color: const Color(0xFFB56A11),
            ),
            DashboardIconMetric(
              icon: AppIcons.statusApproved,
              tooltip: 'Verified',
              count: '${vm.verifiedPayments}',
              color: const Color(0xFF177C50),
            ),
            DashboardIconMetric(
              icon: AppIcons.statusRejected,
              tooltip: 'Rejected',
              count: '${vm.rejectedPayments}',
              color: const Color(0xFFB93838),
            ),
          ],
          label: 'Payments',
          icon: AppIcons.payments,
          iconBgColor: const Color(0xFFFFF4E8),
        ),
      ],
    );
  }

  Widget _buildStatusAndDetailsRow(StudentDashboardVm vm) {
    return ResponsivePair(
      spacing: ResponsiveHelper.dashboardSectionGap(context),
      first: _buildStudentDetails(vm),
      second: ChartCard(
        title: 'Idea Status Distribution',
        child: ResponsiveChartBox(
          desktopHeight: 188,
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

  Widget _buildStudentDetails(StudentDashboardVm vm) {
    return ChartCard(
      title: 'Student Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _detailRow(icon: AppIcons.student, label: 'Student', value: vm.studentName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.departments, label: 'Department', value: vm.department),
          const SizedBox(height: 8),
          _detailRow(
            icon: AppIcons.teams,
            label: 'Team',
            value: vm.team.teamName.isEmpty ? '-' : vm.team.teamName,
          ),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.faculty, label: 'Mentor', value: vm.mentorName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.departments, label: 'Dept Admin', value: vm.departmentAdminName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.organizations, label: 'College Admin', value: vm.collegeAdminName),
          const SizedBox(height: 8),
          _detailRow(icon: AppIcons.organizations, label: 'Organization', value: vm.organizationName),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(StudentDashboardVm vm) {
    final visible = vm.activities.take(_activityLimit).toList(growable: false);
    return SectionContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Text('No recent activity.')
          else
            ...visible.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
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
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 22,
          child: Icon(icon, size: 16, color: const Color(0xFF57629A)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B556A), fontWeight: FontWeight.w600),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13, color: Color(0xFF4B556A))),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return formatDateTime(date);
  }

}

