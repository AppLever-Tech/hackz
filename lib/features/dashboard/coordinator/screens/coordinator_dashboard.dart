import 'package:flutter/material.dart';
import 'package:hackz/core/ui/loading/hkz_progress_indicator.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../services/coordinator_dashboard_service.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../widgets/coordinator_activity_feed.dart';
import '../widgets/submission_workflow_funnel.dart';
import '../widgets/verification_trend_chart.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../chrome/dashboard_components.dart';
import '../../../../features/team/screens/team_registration_screen.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/responsive/responsive_columns.dart';
import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../../core/responsive/responsive_metric_grid.dart';

class CoordinatorDashboard extends StatelessWidget {
  const CoordinatorDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.coordinator) {
      return const Scaffold(body: Center(child: Text('Access denied: Coordinator only')));
    }
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return TeamRegistrationScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        return _CoordinatorSummaryView(
          key: ValueKey<int>(refreshToken),
          user: user,
          refreshToken: refreshToken,
        );
      },
    );
  }
}

class _CoordinatorSummaryView extends StatefulWidget {
  const _CoordinatorSummaryView({super.key, required this.user, required this.refreshToken});

  final UserModel user;
  final int refreshToken;

  @override
  State<_CoordinatorSummaryView> createState() => _CoordinatorSummaryViewState();
}

class _CoordinatorSummaryViewState extends State<_CoordinatorSummaryView> {
  CoordinatorDashboardTimeframe _trendTimeframe = CoordinatorDashboardTimeframe.currentWeek;
  CoordinatorDashboardTimeframe _activityTimeframe = CoordinatorDashboardTimeframe.currentWeek;
  late Future<CoordinatorDashboardAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _future = CoordinatorDashboardService.load(widget.user, forceRefresh: widget.refreshToken > 0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CoordinatorDashboardAnalytics>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HkzProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load coordinator dashboard: ${snapshot.error}');
        }
        final analytics = snapshot.data!;
        final gap = ResponsiveHelper.dashboardSectionGap(context);
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _OperationalMetricGrid(analytics: analytics),
              SizedBox(height: gap),
              DashboardPairRow(
                height: DashboardLayoutTokens.coordinatorChartsRowHeight(
                  analytics.workflow.length,
                ),
                pair: ResponsivePair(
                  spacing: gap,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  first: SectionContainer(
                    child: VerificationTrendChart(
                      points: analytics.trendFor(_trendTimeframe),
                      selectedTimeframe: _trendTimeframe,
                      onTimeframeChanged: (CoordinatorDashboardTimeframe timeframe) {
                        setState(() => _trendTimeframe = timeframe);
                      },
                    ),
                  ),
                  second: SectionContainer(
                    child: SubmissionWorkflowFunnel(steps: analytics.workflow),
                  ),
                ),
              ),
              SizedBox(height: gap),
              SectionContainer(
                child: CoordinatorActivityFeed(
                  activities: analytics.recentActivity,
                  selectedTimeframe: _activityTimeframe,
                  onTimeframeChanged: (CoordinatorDashboardTimeframe timeframe) {
                    setState(() => _activityTimeframe = timeframe);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OperationalMetricGrid extends StatelessWidget {
  const _OperationalMetricGrid({required this.analytics});

  final CoordinatorDashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.single(
          label: 'Pending Payments',
          value: '${analytics.pendingPayments}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.pendingUsers,
        ),
        DashboardMetricChipData.single(
          label: 'Verified Today',
          value: '${analytics.verifiedPaymentsToday}',
          color: const Color(0xFF16A34A),
          icon: AppIcons.verification,
        ),
        DashboardMetricChipData.single(
          label: 'Payments Awaiting Validation',
          value: '${analytics.ideasAwaitingValidation}',
          color: const Color(0xFF0EA5E9),
          icon: AppIcons.submissions,
        ),
        DashboardMetricChipData.single(
          label: 'Rejected Payments',
          value: '${analytics.rejectedPayments}',
          color: const Color(0xFFDC2626),
          icon: AppIcons.workflowRejected,
        ),
      ],
    );
  }
}

