import 'package:flutter/material.dart';

import '../../../../core/firebase/tenant_registry.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../features/organization/models/enums/organization_type.dart';
import '../../../../features/user/models/enums/user_role.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../../../../features/user/models/user_model.dart';
import '../../../../features/app_metadata/screens/app_metadata_management_screen.dart';
import '../../chrome/dashboard_page_template.dart';
import '../../chrome/dashboard_components.dart';
import 'organization_dialog.dart';
import '../../../../features/sysadmin/sysadmin.dart';
import '../../../../utils/firestore_utils.dart';
import '../services/sysadmin_dashboard_service.dart';
import '../../../../core/ui/inputs/filter_pill.dart';
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

  Future<List<OrganizationModel>> _loadOrganizations() {
    return FirestoreUtils.getOrganizations();
  }

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
          return _OrganizationDetailsView(
            refreshToken: refreshToken,
            loadOrganizations: _loadOrganizations,
          );
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

class _OrganizationDetailsView extends StatefulWidget {
  const _OrganizationDetailsView({
    required this.refreshToken,
    required this.loadOrganizations,
  });

  final int refreshToken;
  final Future<List<OrganizationModel>> Function() loadOrganizations;

  @override
  State<_OrganizationDetailsView> createState() => _OrganizationDetailsViewState();
}

class _OrganizationDetailsViewState extends State<_OrganizationDetailsView> {
  /// `null` = show all organizations (client-side filter on [_allOrgs]).
  OrganizationType? _typeFilter;

  List<OrganizationModel> _allOrgs = <OrganizationModel>[];
  Map<String, OrgOperationalData> _operationalByOrgId = <String, OrgOperationalData>{};
  Map<String, String> _organisationCodeByName = <String, String>{};
  bool _loading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
  }

  @override
  void didUpdateWidget(covariant _OrganizationDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _fetchOrganizations();
    }
  }

  Future<void> _fetchOrganizations() async {
    setState(() {
      _loading = true;
      _fetchError = null;
    });
    try {
      final list = await widget.loadOrganizations();
      final operationalFuture = OrgManagementService.loadOperationalData(list);
      final tenantsFuture = TenantRegistry.list();
      final operational = await operationalFuture;
      final codes = TenantRegistry.uniqueCodesByOrganisationName(await tenantsFuture);
      if (!mounted) return;
      setState(() {
        _allOrgs = list;
        _operationalByOrgId = operational;
        _organisationCodeByName = codes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetchError = e.toString();
        _loading = false;
      });
    }
  }

  void _refreshList() {
    _fetchOrganizations();
  }

  Map<OrganizationType, int> _countByType(List<OrganizationModel> orgs) {
    final map = <OrganizationType, int>{
      for (final OrganizationType t in OrganizationType.values) t: 0,
    };
    for (final OrganizationModel o in orgs) {
      map[o.type] = (map[o.type] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fetchError != null) {
      return Text('Unable to load organizations: $_fetchError');
    }

    final organizations = _allOrgs;
    final counts = _countByType(organizations);
    final typesPresent =
        OrganizationType.values.where((OrganizationType t) => (counts[t] ?? 0) > 0).toList(growable: false);

    final filtered = _typeFilter == null
        ? organizations
        : organizations.where((OrganizationModel o) => o.type == _typeFilter).toList(growable: false);

    return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          FilterPill(
                            selected: _typeFilter == null,
                            icon: AppIcons.organizations,
                            label: 'All',
                            count: organizations.length,
                            onTap: () => setState(() => _typeFilter = null),
                          ),
                          if (typesPresent.isNotEmpty) ...<Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: SizedBox(
                                height: 28,
                                child: VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            ...typesPresent.map(
                              (OrganizationType t) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterPill(
                                  selected: _typeFilter == t,
                                  icon: AppIcons.forOrganizationType(t),
                                  label: t.displayName,
                                  count: counts[t] ?? 0,
                                  onTap: () => setState(() => _typeFilter = t),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      final created = await showOrganizationDialog(context: context);
                      if (created && mounted) {
                        _refreshList();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6A38FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Create Organization'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OrganizationManagementGrid(
                organizations: filtered,
                operationalByOrgId: _operationalByOrgId,
                organisationCodeByName: _organisationCodeByName,
                onOrganizationChanged: _refreshList,
              ),
            ],
          ),
        );
  }
}

