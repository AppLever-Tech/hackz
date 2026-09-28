import 'package:flutter/material.dart';

import '../../../../core/responsive/adaptive_dashboard_panel.dart';
import '../../../../core/responsive/responsive_columns.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_layout_tokens.dart';
import '../../../../core/ui/common/dashboard_card/dashboard_pair_row.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../../features/user/models/user_model.dart';
import '../../deptadmin/services/department_dashboard_service.dart';
import '../services/college_dashboard_analytics.dart';
import '../services/college_dashboard_loader.dart';
import 'college_dashboard_charts.dart';
import 'college_overview_card.dart';
import 'college_role_distribution_card.dart';

class CollegeAdminOverview extends StatefulWidget {
  const CollegeAdminOverview({super.key, required this.user});

  final UserModel user;

  @override
  State<CollegeAdminOverview> createState() => _CollegeAdminOverviewState();
}

class _CollegeAdminOverviewState extends State<CollegeAdminOverview> {
  late Future<CollegeDashboardSnapshot> _future;
  DepartmentAnalyticsTimeframe _chartTimeframe = DepartmentAnalyticsTimeframe.lastMonth;
  CollegeChartRowLayout _chartLayout = CollegeChartRowLayout.balanced;

  @override
  void initState() {
    super.initState();
    _future = CollegeDashboardLoader.load(widget.user.orgId);
  }

  @override
  void didUpdateWidget(covariant CollegeAdminOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.orgId != widget.user.orgId) {
      _future = CollegeDashboardLoader.load(widget.user.orgId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CollegeDashboardSnapshot>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<CollegeDashboardSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HkzProgressIndicator(size: 48));
        }
        if (snapshot.hasError) {
          return Text('Unable to load college dashboard: ${snapshot.error}');
        }
        final CollegeDashboardSnapshot? data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No college dashboard data available.'));
        }

        final CollegeRoleMetrics metrics = data.roleMetrics;
        final CollegeDepartmentComparison deptChart = data.departmentComparison(_chartTimeframe);
        final List<CollegeTrendPoint> ideaTrend = data.ideaActivityTrend(_chartTimeframe);
        final double gap = ResponsiveHelper.dashboardSectionGap(context);
        final double overviewRowHeight = DashboardLayoutTokens.collegeOverviewPairRowHeight();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DashboardPairRow(
                height: overviewRowHeight,
                pair: ResponsivePair(
                  spacing: gap,
                  firstFlex: 3,
                  secondFlex: 2,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  first: AdaptiveDashboardPanel(
                    desktopHeight: overviewRowHeight,
                    child: CollegeOverviewCard(user: widget.user, organization: data.org),
                  ),
                  second: AdaptiveDashboardPanel(
                    desktopHeight: overviewRowHeight,
                    child: CollegeRoleDistributionCard(metrics: metrics),
                  ),
                ),
              ),
              SizedBox(height: gap),
              CollegeChartsSection(
                deptData: deptChart,
                ideaPoints: ideaTrend,
                timeframe: _chartTimeframe,
                onTimeframeChanged: (DepartmentAnalyticsTimeframe value) {
                  setState(() => _chartTimeframe = value);
                },
                layout: _chartLayout,
                onLayoutChanged: (CollegeChartRowLayout value) {
                  setState(() => _chartLayout = value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
