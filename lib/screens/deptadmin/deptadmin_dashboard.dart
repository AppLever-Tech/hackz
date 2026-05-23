import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../utils/department_dashboard_service.dart';
import '../../utils/idea_role_config.dart';
import '../../utils/problem_role_config.dart';
import '../../widgets/deptadmin/department_alerts_section.dart';
import '../../widgets/deptadmin/department_metric_card.dart';
import '../../widgets/deptadmin/department_trend_chart.dart';
import '../../widgets/deptadmin/recent_department_activity_card.dart';
import '../../widgets/common/dashboard_trend_chart_layout.dart';
import '../../widgets/deptadmin/user_distribution_widget.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../common/ideas_list_screen.dart';
import '../common/problems_list_screen.dart';
import 'judges_panel.dart';
import 'manage_users_screen.dart';
import '../../responsive/responsive_helper.dart';
import '../../widgets/common/dashboard_panel_column.dart';
import '../../widgets/common/dashboard_scrollable_list_layout.dart';
import '../../widgets/responsive/adaptive_dashboard_panel.dart';
import '../../widgets/responsive/responsive_dashboard_pair_row.dart';
import '../../widgets/responsive/responsive_columns.dart';
import '../../widgets/dashboard/dashboard_metric_chips.dart';
import '../../widgets/responsive/responsive_metric_grid.dart';
import '../../workspace/workspace.dart';
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

  static const int _kNarrowPanelFlex = 35;
  static const int _kWidePanelFlex = 65;
  /// Title block (≈50) + donut row (132); trend card uses [DashboardTrendChartLayout.trendCardContentHeight].
  static const double _kUsersByRoleContentHeight = 50 + 132;

  static double get _kUsersTrendRowHeight {
    final double trendHeight = DashboardTrendChartLayout.trendCardContentHeight;
    return trendHeight > _kUsersByRoleContentHeight ? trendHeight : _kUsersByRoleContentHeight;
  }

  static const double _kProblemsIdeasRowHeight = 252;
  static const double _kAlertsActivityRowHeight = 390;
  static const double _kListIconSize = 18;

  @override
  Widget build(BuildContext context) {
    final gap = ResponsiveHelper.dashboardSectionGap(context);
    final int problemsWithIdeas =
        analytics.departmentProblems.where((DepartmentProblemPreview p) => p.ideaCount > 0).length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ResponsiveMetricGrid(
            chips: <DashboardMetricChipData>[
              DepartmentMetricCard(
                value: '${analytics.totalActiveUsers}',
                label: 'Total Active Users',
                icon: AppIcons.users,
                iconBgColor: const Color(0xFFEAF2FF),
                footnote: '${analytics.studentCount} students · ${analytics.facultyCount} faculty',
                tooltip: 'Active faculty, students, coordinators and judges in this department.',
              ).toChipData(),
              DepartmentMetricCard(
                value: '${analytics.pendingApprovals}',
                label: 'Pending Approvals',
                icon: AppIcons.pendingUsers,
                iconBgColor: const Color(0xFFFFF7E6),
                footnote: '${analytics.pendingCoordinatorJudgeCount} coordinator/judge requests',
                tooltip: 'Users waiting for department onboarding approval.',
              ).toChipData(),
              DepartmentMetricCard(
                value: '${analytics.activeProblems}',
                label: 'Active Problems',
                icon: AppIcons.problems,
                iconBgColor: const Color(0xFFE9FAF0),
                footnote: '$problemsWithIdeas problems receiving ideas',
                tooltip: 'Currently active problem statements in this department.',
              ).toChipData(),
              DepartmentMetricCard(
                value: '${analytics.ideasSubmitted}',
                label: 'Ideas Submitted',
                icon: AppIcons.ideas,
                iconBgColor: const Color(0xFFF2EDFF),
                footnote: '${analytics.evaluatedIdeas} evaluated · ${analytics.pendingPayments} payments pending',
                tooltip: 'Department idea submissions and related operational workload.',
              ).toChipData(),
            ],
          ),
          SizedBox(height: gap),
          ResponsiveDashboardPairRow(
            height: _kProblemsIdeasRowHeight,
            pair: ResponsivePair(
              spacing: gap,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              first: AdaptiveDashboardPanel(
                desktopHeight: _kProblemsIdeasRowHeight,
                child: _DepartmentProblemsCard(problems: analytics.departmentProblems),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: _kProblemsIdeasRowHeight,
                child: _DepartmentIdeasCard(ideas: analytics.departmentIdeas),
              ),
            ),
          ),
          SizedBox(height: gap),
          ResponsiveDashboardPairRow(
            height: _kUsersTrendRowHeight,
            pair: ResponsivePair(
              spacing: gap,
              firstFlex: _kNarrowPanelFlex,
              secondFlex: _kWidePanelFlex,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              first: AdaptiveDashboardPanel(
                desktopHeight: _kUsersTrendRowHeight,
                child: UserDistributionWidget(
                  title: 'Users by Role',
                  subtitle: 'Active role mix plus pending onboarding queue',
                  segments: analytics.usersByRole,
                ),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: _kUsersTrendRowHeight,
                child: DepartmentTrendChart(
                  points: analytics.trendFor(trendTimeframe),
                  selectedTimeframe: trendTimeframe,
                  onTimeframeChanged: onTrendChanged,
                ),
              ),
            ),
          ),
          SizedBox(height: gap),
          ResponsiveDashboardPairRow(
            height: _kAlertsActivityRowHeight,
            pair: ResponsivePair(
              spacing: gap,
              firstFlex: _kNarrowPanelFlex,
              secondFlex: _kWidePanelFlex,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              first: AdaptiveDashboardPanel(
                desktopHeight: _kAlertsActivityRowHeight,
                child: DepartmentAlertsSection(alerts: analytics.alerts),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: _kAlertsActivityRowHeight,
                child: RecentDepartmentActivityCard(
                  events: analytics.recentActivity,
                  selectedTimeframe: activityTimeframe,
                  onTimeframeChanged: onActivityChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentListCardHeader extends StatelessWidget {
  const _DepartmentListCardHeader({
    required this.title,
    required this.icon,
    required this.iconBgColor,
    required this.count,
  });

  final String title;
  final IconData icon;
  final Color iconBgColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: icon == AppIcons.problems ? const Color(0xFFEA580C) : const Color(0xFF6A38FF)),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF3552CC)),
          ),
        ),
      ],
    );
  }
}

class _DepartmentProblemsCard extends StatelessWidget {
  const _DepartmentProblemsCard({required this.problems});

  final List<DepartmentProblemPreview> problems;

  @override
  Widget build(BuildContext context) {
    final int count = problems.length;
    return DashboardPanelColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      headers: <Widget>[
        _DepartmentListCardHeader(
          title: 'My Department Problems',
          icon: AppIcons.problems,
          iconBgColor: const Color(0xFFFFF4ED),
          count: count,
        ),
        const SizedBox(height: 12),
      ],
      listBuilder: ({required bool expandVertically}) => DashboardScrollableList(
        expandVertically: expandVertically,
        itemCount: count,
        rowStride: DashboardScrollableListLayout.compactRowStride,
        separatorHeight: DashboardScrollableListLayout.compactSeparatorHeight,
        padding: ContextPillMetrics.clippedListPadding,
        empty: const Center(child: Text('-', style: TextStyle(color: Color(0xFF6E7394)))),
        itemBuilder: (BuildContext context, int index) =>
            _problemPreviewRow(context, problems[index]),
      ),
    );
  }

  Widget _problemPreviewRow(BuildContext context, DepartmentProblemPreview problem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: problem.problemId.trim().isNotEmpty
              ? ContextPill(
                  label: problem.title,
                  semantic: ContextPillSemantic.problem,
                  onTap: () => WorkspaceNavigator.openProblem(context, problem.problemId),
                  compact: true,
                  expandWidth: true,
                )
              : Text(
                  problem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(width: 8),
        const Icon(
          AppIcons.ideas,
          size: _DepartmentAnalyticsView._kListIconSize,
          color: Color(0xFF4A4F73),
        ),
        const SizedBox(width: 4),
        Text(
          '${problem.ideaCount}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF4A4F73)),
        ),
      ],
    );
  }
}

class _DepartmentIdeasCard extends StatelessWidget {
  const _DepartmentIdeasCard({required this.ideas});

  final List<DepartmentIdeaPreview> ideas;

  @override
  Widget build(BuildContext context) {
    final int count = ideas.length;
    return DashboardPanelColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      headers: <Widget>[
        _DepartmentListCardHeader(
          title: 'My Department Ideas',
          icon: AppIcons.ideas,
          iconBgColor: const Color(0xFFF2EDFF),
          count: count,
        ),
        const SizedBox(height: 12),
      ],
      listBuilder: ({required bool expandVertically}) => DashboardScrollableList(
        expandVertically: expandVertically,
        itemCount: count,
        rowStride: DashboardScrollableListLayout.compactRowStride,
        separatorHeight: DashboardScrollableListLayout.compactSeparatorHeight,
        padding: ContextPillMetrics.clippedListPadding,
        empty: const Center(child: Text('-', style: TextStyle(color: Color(0xFF6E7394)))),
        itemBuilder: (BuildContext context, int index) => _ideaPreviewRow(context, ideas[index]),
      ),
    );
  }

  Widget _ideaPreviewRow(BuildContext context, DepartmentIdeaPreview idea) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
          Expanded(
            child: idea.ideaId.trim().isNotEmpty
                ? ContextPill(
                    label: idea.title,
                    semantic: ContextPillSemantic.idea,
                    onTap: () => WorkspaceNavigator.openIdea(context, idea.ideaId),
                    compact: true,
                    expandWidth: true,
                  )
                : Text(
                    idea.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 8),
        StatusStyles.ideaStatusIcon(
          idea.status,
          size: _DepartmentAnalyticsView._kListIconSize,
        ),
      ],
    );
  }
}
