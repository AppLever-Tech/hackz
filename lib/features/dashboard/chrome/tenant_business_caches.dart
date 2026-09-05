import '../../evaluations/services/judge_evaluation_service.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../payment/services/department_payments_service.dart';
import '../../team/services/teams_workspace_service.dart';
import '../coordinator/services/coordinator_dashboard_service.dart';
import '../deptadmin/services/department_dashboard_service.dart';
import '../sysadmin/services/sysadmin_dashboard_service.dart';

/// In-memory organisation-data caches. Cleared whenever the active tenant
/// Firebase project changes so Tenant A data cannot leak into Tenant B.
abstract final class TenantBusinessCaches {
  TenantBusinessCaches._();

  static void clear() {
    OrgSettingsService.instance.clearCache();
    SysAdminDashboardService.clearCache();
    DepartmentDashboardService.clearCache();
    TeamsWorkspaceService.clearCache();
    CoordinatorDashboardService.clearCache();
    JudgeEvaluationService.clearCache();
    DepartmentPaymentsService.clearCache();
  }
}
