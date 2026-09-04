import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/app_metadata/screens/app_metadata_management_screen.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../chrome/dashboard_components.dart';
import '../../../../features/sysadmin/onboarding/screens/organisations_onboarding_console.dart';
import '../services/sysadmin_dashboard_service.dart';
import '../widgets/innovation_funnel_widget.dart';
import '../widgets/organization_analytics_chart.dart';
import '../widgets/participation_trend_chart.dart';
import '../widgets/platform_alerts_section.dart';
import '../widgets/platform_distribution_chart.dart';
import '../widgets/platform_metric_card.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_card_layout.dart';
import '../../../../core/responsive/adaptive_dashboard_panel.dart';
import '../../../../core/responsive/responsive_columns.dart';
import '../../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../../core/responsive/responsive_metric_grid.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../widgets/recent_platform_activity_card.dart';

class SysAdminDashboard extends StatelessWidget {
  const SysAdminDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.sysAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access denied: SysAdmin only')),
      );
    }

    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (BuildContext context, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 2) {
          return AppMetadataManagementScreen(key: ValueKey<int>(refreshToken));
        }
        if (selectedMenuIndex == 1) {
          return OrganisationsOnboardingConsole(key: ValueKey<int>(refreshToken), refreshToken: refreshToken);
        }
        return _SysAdminOverview(refreshToken: refreshToken);
      },
    );
  }
}

class _SysAdminOverview extends StatefulWidget {
  const _SysAdminOverview({required this.refreshToken});

  final int refreshToken;

  @override
  State<_SysAdminOverview> createState() => _SysAdminOverviewState();
}

class _SysAdminOverviewState extends State<_SysAdminOverview> {
  late Future<SysAdminDashboardAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _future = SysAdminDashboardService.load();
  }

  @override
  void didUpdateWidget(covariant _SysAdminOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(() {
        _future = SysAdminDashboardService.load(forceRefresh: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SysAdminDashboardAnalytics>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<SysAdminDashboardAnalytics> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load platform analytics: ${snapshot.error}');
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No platform analytics available yet.'));
        }
        return _SysAdminAnalyticsView(data: data);
      },
    );
  }
}

class _SysAdminAnalyticsView extends StatefulWidget {
  const _SysAdminAnalyticsView({required this.data});

  final SysAdminDashboardAnalytics data;

  @override
  State<_SysAdminAnalyticsView> createState() => _SysAdminAnalyticsViewState();
}

class _SysAdminAnalyticsViewState extends State<_SysAdminAnalyticsView> {
  PlatformAnalyticsTimeframe _trendTimeframe = PlatformAnalyticsTimeframe.currentWeek;
  PlatformAnalyticsTimeframe _activityTimeframe = PlatformAnalyticsTimeframe.currentWeek;

  @override
  Widget build(BuildContext context) {
    final SysAdminDashboardAnalytics data = widget.data;
    final gap = ResponsiveHelper.dashboardSectionGap(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ResponsiveMetricGrid(
            chips: <DashboardMetricChipData>[
              PlatformMetricCard(
                label: 'Active Organizations',
                value: '${data.activeOrganizations}',
                icon: AppIcons.organizations,
                accent: const Color(0xFF2563EB),
                caption: 'Recent ecosystem activity',
              ).toChipData(),
              PlatformMetricCard(
                label: 'Total Active Users',
                value: '${data.totalActiveUsers}',
                icon: AppIcons.users,
                accent: const Color(0xFF7C3AED),
                caption: 'Approved platform users',
              ).toChipData(),
              PlatformMetricCard(
                label: 'Ideas Submitted',
                value: '${data.ideasSubmitted}',
                icon: AppIcons.ideas,
                accent: const Color(0xFFEA580C),
                caption: 'All submitted ideas',
              ).toChipData(),
              PlatformMetricCard(
                label: 'Approval Rate',
                value: '${(data.approvalRate * 100).round()}%',
                icon: AppIcons.workflowApproved,
                accent: const Color(0xFF16A34A),
                caption: 'Active users / registrations',
              ).toChipData(),
            ],
          ),
          SizedBox(height: gap),
          SectionContainer(
            child: ParticipationTrendChart(
              points: data.trendFor(_trendTimeframe),
              selectedTimeframe: _trendTimeframe,
              onTimeframeChanged: (PlatformAnalyticsTimeframe timeframe) {
                setState(() => _trendTimeframe = timeframe);
              },
            ),
          ),
          SizedBox(height: gap),
          ResponsivePair(
            spacing: gap,
            first: SectionContainer(child: InnovationFunnelWidget(steps: data.funnel)),
            second: SectionContainer(child: OrganizationAnalyticsChart(points: data.organizationActivity)),
          ),
          SizedBox(height: gap),
          DashboardPairRow(
            height: DashboardLayoutTokens.pairRowDistribution,
            pair: ResponsivePair(
              spacing: gap,
              first: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowDistribution,
                child: PlatformDistributionChart(
                  title: 'Users by Role',
                  subtitle: 'Operational identity mix across the platform',
                  segments: data.usersByRole,
                ),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowDistribution,
                child: PlatformDistributionChart(
                  title: 'Idea Status Mix',
                  subtitle: 'Submission lifecycle distribution',
                  segments: data.ideaStatusDistribution,
                ),
              ),
            ),
          ),
          SizedBox(height: gap),
          DashboardPairRow(
            height: DashboardLayoutTokens.pairRowAlertsActivity,
            pair: ResponsivePair(
              spacing: gap,
              first: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowAlertsActivity,
                child: PlatformAlertsSection(alerts: data.alerts),
              ),
              second: AdaptiveDashboardPanel(
                desktopHeight: DashboardLayoutTokens.pairRowAlertsActivity,
                child: RecentPlatformActivityCard(
                  events: data.recentActivity,
                  selectedTimeframe: _activityTimeframe,
                  onTimeframeChanged: (PlatformAnalyticsTimeframe timeframe) {
                    setState(() => _activityTimeframe = timeframe);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

