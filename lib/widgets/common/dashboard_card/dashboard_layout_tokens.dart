import '../dashboard_trend_chart_layout.dart';

/// Central layout constants for role dashboard cards and pair rows.
abstract final class DashboardLayoutTokens {
  // Pair-row heights (side-by-side desktop layout only; see [DashboardPairRow]).
  static const double pairRowList = 252;
  static const double pairRowAlertsActivity = 380;
  static const double pairRowAlertsActivityDept = 390;
  static const double pairRowDistribution = 236;
  static const double studentDetailsRowHeight = 200;

  // Coordinator dashboard panels.
  static const double coordinatorTrendRow = 380;
  static const double coordinatorActivityPanel = 360;
  static const double coordinatorSnapshotPanel = 245;

  // ResponsivePair flex weights.
  static const int narrowPanelFlex = 35;
  static const int widePanelFlex = 65;

  // Vertical spacing inside dashboard cards.
  static const double titleSubtitleGap = 4;
  static const double bodyTopGap = 14;
  static const double iconCountHeaderGap = 12;
  static const double chartHeaderSpacing = 10;
  static const double activityHeaderGap = 10;

  // Donut distribution cards.
  static const double donutSizePlatform = 124;
  static const double donutSizeDepartment = 132;

  // Charts in stacked (unbounded) layouts.
  static const double stackedChartHeight = 180;

  // Dynamic lists.
  static const int listMaxVisibleRows = 5;

  static const double listCompactRowStride = 44;
  static const double listCompactSeparator = 8;

  static const double listActivityRowStride = 60;
  static const double listActivitySeparator = 12;

  static const double listDepartmentActivityRowStride = 64;
  static const double listDepartmentActivitySeparator = 9;

  static const double listAlertRowStride = 72;
  static const double listAlertSeparator = 10;

  static const double listActivityEmptyHeight = 72;

  /// Deptadmin users-by-role donut block (title + 132px chart).
  static const double usersByRoleBlockHeight = 50 + donutSizeDepartment;

  static double get trendCardContentHeight => DashboardTrendChartLayout.trendCardContentHeight;

  static double usersTrendRowHeight() {
    final double trend = trendCardContentHeight;
    return trend > usersByRoleBlockHeight ? trend : usersByRoleBlockHeight;
  }
}
