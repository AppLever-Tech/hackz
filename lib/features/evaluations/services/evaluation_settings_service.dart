import '../../evaluations/constants/default_evaluation_templates.dart';
import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';
import 'evaluation_aggregation_sync_service.dart';

/// Reads evaluation-related org settings for scoring and aggregation workflows.
abstract final class EvaluationSettingsService {
  EvaluationSettingsService._();

  static Future<void> ensureLoaded({
    required String orgId,
    bool force = false,
  }) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId, force: force);
  }

  /// After Evaluation Configuration changes that affect idea lifecycle, re-sync
  /// org ideas so Department Admin / Faculty / Judges see updated evaluation gates.
  static Future<void> reconcileAfterEvaluationConfigChange({
    required String orgId,
  }) async {
    await EvaluationAggregationSyncService.reconcileOrg(orgId: orgId);
  }

  static int requiredJudgeEvaluations(String orgId) {
    final Object? raw = OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.requiredJudgeEvaluations];
    if (raw is int) return raw.clamp(1, 15);
    if (raw is num) return raw.round().clamp(1, 15);
    return 2;
  }

  static int defaultScoringScale() => defaultEvaluationTemplates.first.scoringScale;
}
