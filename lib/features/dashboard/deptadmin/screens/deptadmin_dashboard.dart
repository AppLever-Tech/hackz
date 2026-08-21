import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/status_styles.dart';
import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../services/department_dashboard_service.dart';
import '../../../../features/idea/services/idea_role_config.dart';
import '../../../../features/problems/services/problem_role_config.dart';
import '../widgets/department_alerts_section.dart';
import '../widgets/department_metric_card.dart';
import '../widgets/department_trend_chart.dart';
import '../widgets/recent_department_activity_card.dart';
import '../widgets/user_distribution_widget.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../../../features/leaderboard/screens/leaderboard_showcase_screen.dart';
import '../../../../features/idea/screens/ideas_list_screen.dart';
import '../../../../features/evaluations/screens/evaluation_results_screen.dart';
import '../../../../features/ideathons/screens/ideathons_list_screen.dart';
import '../../../../features/evaluations/screens/department_evaluation_extensions_screen.dart';
import '../../../../features/problems/screens/problem_statements/problem_statements_table_screen.dart';
import '../../../../features/evaluations/screens/judges_panel.dart';
import '../../../../features/domain/domain.dart';
import '../../../../features/user/screens/manage_users_screen.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../../../../core/responsive/adaptive_dashboard_panel.dart';
import '../../../../core/responsive/responsive_columns.dart';
import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../../core/responsive/responsive_metric_grid.dart';
import '../../../../features/requests/deptadmin/screens/requests_workspace_screen.dart';
import 'package:hackz/features/payment/screens/payments_screen.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_metrics.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

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
          return DeptDomainManagementHost(
            key: ValueKey<int>(refreshToken),
            orgId: user.orgId,
            departmentCode: user.departmentCode,
            departmentName: user.department,
          );
        }
        if (selectedMenuIndex == 3) {
          return ProblemStatementsTableScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: ProblemRoleConfig.configFor(UserRole.departmentAdmin, user),
          );
        }
        if (selectedMenuIndex == 4) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.departmentAdmin, user),
          );
        }
        if (selectedMenuIndex == 5) {
          return EvaluationResultsScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 6) {
          return IdeathonsListScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 7) {
          return DepartmentEvaluationExtensionsScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 8) {
          return JudgesPanelScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 9) {
          return PaymentsScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 10) {
          return RequestsWorkspaceScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 11) {
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
                footnote: '${analytics.studentCount} team members · ${analytics.facultyCount} faculty',
                tooltip: 'Active faculty, team members, coordinators and judges in this department.',
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
          DashboardPairRow(
            height: DashboardLayoutTokens.pairRowList,
            pair: ResponsivePair(
              spacing: gap,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              first: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowList,
                child: _DepartmentProblemsCard(problems: analytics.departmentProblems),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowList,
                child: _DepartmentIdeasCard(ideas: analytics.departmentIdeas),
              ),
            ),
          ),
          SizedBox(height: gap),
          DashboardPairRow(
            height: DashboardLayoutTokens.usersTrendRowHeight(),
            pair: ResponsivePair(
              spacing: gap,
              firstFlex: DashboardLayoutTokens.narrowPanelFlex,
              secondFlex: DashboardLayoutTokens.widePanelFlex,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              first: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.usersTrendRowHeight(),
                child: UserDistributionWidget(
                  title: 'Users by Role',
                  subtitle: 'Active role mix plus pending onboarding queue',
                  segments: analytics.usersByRole,
                ),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.usersTrendRowHeight(),
                child: DepartmentTrendChart(
                  points: analytics.trendFor(trendTimeframe),
                  selectedTimeframe: trendTimeframe,
                  onTimeframeChanged: onTrendChanged,
                ),
              ),
            ),
          ),
          SizedBox(height: gap),
          DashboardPairRow(
            height: DashboardLayoutTokens.pairRowAlertsActivityDept,
            pair: ResponsivePair(
              spacing: gap,
              firstFlex: DashboardLayoutTokens.narrowPanelFlex,
              secondFlex: DashboardLayoutTokens.widePanelFlex,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              first: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowAlertsActivityDept,
                child: DepartmentAlertsSection(alerts: analytics.alerts),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowAlertsActivityDept,
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

class _DepartmentProblemsCard extends StatelessWidget {
  const _DepartmentProblemsCard({required this.problems});

  final List<DepartmentProblemPreview> problems;

  @override
  Widget build(BuildContext context) {
    final int count = problems.length;
    return DashboardListCard(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      preset: DashboardListPreset.compact,
      padding: ContextPillMetrics.clippedListPadding,
      headers: <Widget>[
        DashboardIconCountHeader(
          title: 'My Department Problems',
          icon: AppIcons.problems,
          iconBgColor: const Color(0xFFFFF4ED),
          iconColor: const Color(0xFFEA580C),
          count: count,
        ),
        const SizedBox(height: DashboardLayoutTokens.iconCountHeaderGap),
      ],
      itemCount: count,
      empty: const Center(child: Text('-', style: TextStyle(color: Color(0xFF6E7394)))),
      itemBuilder: (BuildContext context, int index) => _problemPreviewRow(context, problems[index]),
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
    return DashboardListCard(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      preset: DashboardListPreset.compact,
      padding: ContextPillMetrics.clippedListPadding,
      headers: <Widget>[
        DashboardIconCountHeader(
          title: 'My Department Ideas',
          icon: AppIcons.ideas,
          count: count,
        ),
        const SizedBox(height: DashboardLayoutTokens.iconCountHeaderGap),
      ],
      itemCount: count,
      empty: const Center(child: Text('-', style: TextStyle(color: Color(0xFF6E7394)))),
      itemBuilder: (BuildContext context, int index) => _ideaPreviewRow(context, ideas[index]),
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
