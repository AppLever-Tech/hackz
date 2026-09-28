import 'dashboard_layout_tokens.dart';

/// Row stride presets for [DashboardScrollableList].
enum DashboardListPreset {
  compact,
  activity,
  departmentActivity,
  alert,
}

extension DashboardListPresetMetrics on DashboardListPreset {
  double get rowStride => switch (this) {
        DashboardListPreset.compact => DashboardLayoutTokens.listCompactRowStride,
        DashboardListPreset.activity => DashboardLayoutTokens.listActivityRowStride,
        DashboardListPreset.departmentActivity => DashboardLayoutTokens.listDepartmentActivityRowStride,
        DashboardListPreset.alert => DashboardLayoutTokens.listAlertRowStride,
      };

  double get separatorHeight => switch (this) {
        DashboardListPreset.compact => DashboardLayoutTokens.listCompactSeparator,
        DashboardListPreset.activity => DashboardLayoutTokens.listActivitySeparator,
        DashboardListPreset.departmentActivity => DashboardLayoutTokens.listDepartmentActivitySeparator,
        DashboardListPreset.alert => DashboardLayoutTokens.listAlertSeparator,
      };
}
