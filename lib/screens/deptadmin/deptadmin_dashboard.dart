import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/department_dashboard_service.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../../widgets/common/idea_status_distribution_donut.dart';
import '../../widgets/deptadmin/department_alerts_section.dart';
import '../../widgets/deptadmin/department_metric_card.dart';
import '../../widgets/deptadmin/department_trend_chart.dart';
import '../../widgets/deptadmin/payment_operations_widget.dart';
import '../../widgets/deptadmin/problem_analytics_widget.dart';
import '../../widgets/deptadmin/recent_department_activity_card.dart';
import '../../widgets/deptadmin/user_distribution_widget.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../common/dashboard_components.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import 'judges_panel.dart';
import 'manage_users_screen.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/responsive/adaptive_dashboard_panel.dart';
import '../../widgets/responsive/responsive_columns.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import 'payments_screen.dart';

class DeptAdminDashboard extends StatelessWidget {
  const DeptAdminDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.departmentAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied: DepartmentAdmin only')),
      );
    }

    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return ManageUsersScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return ProblemsListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.departmentAdmin, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.departmentAdmin, user),
          );
        }
        if (selectedMenuIndex == 4) {
          return JudgesPanelScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 5) {
          return PaymentsScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 6) {
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }

        return _DeptAdminOverview(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}

class _DeptAdminOverview extends StatefulWidget {
  const _DeptAdminOverview({super.key, required this.user});

  final UserModel user;

  @override
  State<_DeptAdminOverview> createState() => _DeptAdminOverviewState();
}

class _DeptAdminOverviewState extends State<_DeptAdminOverview> {
  DepartmentAnalyticsTimeframe _trendTimeframe = DepartmentAnalyticsTimeframe.currentWeek;
  DepartmentAnalyticsTimeframe _activityTimeframe = DepartmentAnalyticsTimeframe.currentWeek;
  late Future<DepartmentDashboardAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(forceRefresh: true);
  }

  @override
  void didUpdateWidget(covariant _DeptAdminOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.orgId != widget.user.orgId || oldWidget.user.departmentCode != widget.user.departmentCode) {
      _future = _load(forceRefresh: true);
    }
  }

  Future<DepartmentDashboardAnalytics> _load({bool forceRefresh = false}) {
    return DepartmentDashboardService.load(
      orgId: widget.user.orgId,
      departmentCode: widget.user.departmentCode,
      forceRefresh: forceRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DepartmentDashboardAnalytics>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<DepartmentDashboardAnalytics> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load department dashboard: ${snapshot.error}');
        }
        final analytics = snapshot.data;
        if (analytics == null) {
          return const Center(child: Text('No department analytics available yet.'));
        }
        return _DepartmentAnalyticsView(
          analytics: analytics,
          trendTimeframe: _trendTimeframe,
          activityTimeframe: _activityTimeframe,
          onTrendChanged: (DepartmentAnalyticsTimeframe timeframe) {
            setState(() => _trendTimeframe = timeframe);
          },
          onActivityChanged: (DepartmentAnalyticsTimeframe timeframe) {
            setState(() => _activityTimeframe = timeframe);
          },
        );
      },
    );
  }
}

class _DepartmentAnalyticsView extends StatelessWidget {
  const _DepartmentAnalyticsView({
    required this.analytics,
    required this.trendTimeframe,
    required this.activityTimeframe,
    required this.onTrendChanged,
    required this.onActivityChanged,
  });

  final DepartmentDashboardAnalytics analytics;
  final DepartmentAnalyticsTimeframe trendTimeframe;
  final DepartmentAnalyticsTimeframe activityTimeframe;
  final ValueChanged<DepartmentAnalyticsTimeframe> onTrendChanged;
  final ValueChanged<DepartmentAnalyticsTimeframe> onActivityChanged;

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.dashboardSectionGap(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveMetricGrid(
            children: <Widget>[
              DepartmentMetricCard(
                value: '${analytics.totalActiveUsers}',
                label: 'Total Active Users',
                icon: AppIcons.users,
                iconBgColor: const Color(0xFFEAF2FF),
                footnote: '${analytics.studentCount} students · ${analytics.facultyCount} faculty',
                tooltip: 'Active faculty, students, coordinators and judges in this department.',
              ),
              DepartmentMetricCard(
                value: '${analytics.pendingApprovals}',
                label: 'Pending Approvals',
                icon: AppIcons.pendingUsers,
                iconBgColor: const Color(0xFFFFF7E6),
                footnote: '${analytics.pendingCoordinatorJudgeCount} coordinator/judge requests',
                tooltip: 'Users waiting for department onboarding approval.',
              ),
              DepartmentMetricCard(
                value: '${analytics.activeProblems}',
                label: 'Active Problems',
                icon: AppIcons.problems,
                iconBgColor: const Color(0xFFE9FAF0),
                footnote: '${analytics.ideaInflowByProblem.length} problems receiving ideas',
                tooltip: 'Currently active problem statements in this department.',
              ),
              DepartmentMetricCard(
                value: '${analytics.ideasSubmitted}',
                label: 'Ideas Submitted',
                icon: AppIcons.ideas,
                iconBgColor: const Color(0xFFF2EDFF),
                footnote: '${analytics.evaluatedIdeas} evaluated · ${analytics.pendingPayments} payments pending',
                tooltip: 'Department idea submissions and related operational workload.',
              ),
            ],
          ),
          SizedBox(height: gap),
          SectionContainer(
            child: DepartmentTrendChart(
              points: analytics.trendFor(trendTimeframe),
              selectedTimeframe: trendTimeframe,
              onTimeframeChanged: onTrendChanged,
            ),
          ),
          SizedBox(height: gap),
          ResponsivePair(
            spacing: gap,
            first: AdaptiveDashboardPanel(
              desktopHeight: 320,
              child: _UserManagementSection(analytics: analytics),
            ),
            second: AdaptiveDashboardPanel(
              desktopHeight: 320,
              child: UserDistributionWidget(
                title: 'Users by Role',
                subtitle: 'Active role mix plus pending onboarding queue',
                segments: analytics.usersByRole,
              ),
            ),
          ),
          SizedBox(height: gap),
          ResponsivePair(
            spacing: gap,
            firstFlex: 7,
            secondFlex: 5,
            first: AdaptiveDashboardPanel(
              desktopHeight: 380,
              child: ProblemAnalyticsWidget(
                activeProblems: analytics.activeProblems,
                problemsByTheme: analytics.problemsByTheme,
                ideaInflowByProblem: analytics.ideaInflowByProblem,
              ),
            ),
            second: AdaptiveDashboardPanel(
              desktopHeight: 380,
              child: PaymentOperationsWidget(
                pendingPayments: analytics.pendingPayments,
                submittedIdeas: analytics.submittedIdeas,
                evaluatedIdeas: analytics.evaluatedIdeas,
                approvedIdeas: analytics.approvedIdeas,
                rejectedIdeas: analytics.rejectedIdeas,
                paymentVerificationRate: analytics.paymentVerificationRate,
                evaluationCompletionRate: analytics.evaluationCompletionRate,
              ),
            ),
          ),
          SizedBox(height: gap),
          ResponsivePair(
            spacing: gap,
            first: AdaptiveDashboardPanel(
              desktopHeight: 350,
              child: _IdeaStatusMixSection(analytics: analytics),
            ),
            second: AdaptiveDashboardPanel(
              desktopHeight: 350,
              child: DepartmentAlertsSection(alerts: analytics.alerts),
            ),
          ),
          SizedBox(height: gap),
          AdaptiveDashboardPanel(
            desktopHeight: 390,
            child: RecentDepartmentActivityCard(
              events: analytics.recentActivity,
              selectedTimeframe: activityTimeframe,
              onTimeframeChanged: onActivityChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdeaStatusMixSection extends StatelessWidget {
  const _IdeaStatusMixSection({required this.analytics});

  final DepartmentDashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Idea Status Mix',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Submission, review, evaluated and decision states',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        if (ResponsiveHelper.isDesktopOrWider(context))
          Expanded(
            child: IdeaStatusDistributionDonut(
              pending: analytics.pendingSubmissionIdeas,
              submitted: analytics.submittedIdeas - analytics.underReviewIdeas,
              underReview: analytics.underReviewIdeas,
              evaluated: analytics.evaluatedOnlyIdeas,
              approved: analytics.approvedIdeas,
              rejected: analytics.rejectedIdeas,
              centerStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              legendTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
          )
        else
          IdeaStatusDistributionDonut(
            pending: analytics.pendingSubmissionIdeas,
            submitted: analytics.submittedIdeas - analytics.underReviewIdeas,
            underReview: analytics.underReviewIdeas,
            evaluated: analytics.evaluatedOnlyIdeas,
            approved: analytics.approvedIdeas,
            rejected: analytics.rejectedIdeas,
            centerStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            legendTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
          ),
      ],
    );
  }
}

class _UserManagementSection extends StatelessWidget {
  const _UserManagementSection({required this.analytics});

  final DepartmentDashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final inFixedPanel = ResponsiveHelper.isDesktopOrWider(context);
    final grid = GridView.count(
      padding: EdgeInsets.zero,
      shrinkWrap: !inFixedPanel,
      physics: inFixedPanel ? null : const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: ResponsiveHelper.isMobile(context) ? 3.2 : 2.3,
      children: <Widget>[
        _RoleStat(label: 'Faculty', value: analytics.facultyCount, icon: AppIcons.faculty, color: const Color(0xFF6A38FF)),
        _RoleStat(label: 'Students', value: analytics.studentCount, icon: AppIcons.student, color: const Color(0xFF0EA5E9)),
        _RoleStat(label: 'Coordinators', value: analytics.coordinatorCount, icon: AppIcons.coordinator, color: const Color(0xFF16A34A)),
        _RoleStat(label: 'Judges', value: analytics.judgeCount, icon: AppIcons.judges, color: const Color(0xFFEA580C)),
        _RoleStat(label: 'Pending approvals', value: analytics.pendingApprovals, icon: AppIcons.pendingUsers, color: const Color(0xFFF59E0B)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('User Management Snapshot', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('Quick role visibility for department operations', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 14),
        if (inFixedPanel) Expanded(child: grid) else grid,
      ],
    );
  }
}

class _RoleStat extends StatelessWidget {
  const _RoleStat({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

