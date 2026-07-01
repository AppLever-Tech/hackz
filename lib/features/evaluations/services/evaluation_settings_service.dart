import '../../evaluations/constants/default_evaluation_templates.dart';
import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';

/// Reads evaluation-related org settings for scoring and shortlisting workflows.
abstract final class EvaluationSettingsService {
  EvaluationSettingsService._();

  static Future<void> ensureLoaded({required String orgId}) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
  }

  static int requiredJudgeEvaluations(String orgId) {
    final Object? raw = OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.requiredJudgeEvaluations];
    if (raw is int) return raw.clamp(1, 15);
    if (raw is num) return raw.round().clamp(1, 15);
    return 2;
  }

  static double recommendationThresholdPercent(String orgId) {
    final Object? raw = OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.recommendationThreshold];
    if (raw is int) return raw.clamp(0, 100).toDouble();
    if (raw is num) return raw.toDouble().clamp(0, 100);
    return 75;
  }

  static bool enableRecommendationEngine(String orgId) {
    final Object? raw = OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.enableRecommendationEngine];
    if (raw is bool) return raw;
    return true;
  }

  static int defaultScoringScale() => defaultEvaluationTemplates.first.scoringScale;
}
