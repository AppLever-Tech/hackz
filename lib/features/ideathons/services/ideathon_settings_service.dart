import '../../evaluations/constants/default_evaluation_templates.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';

/// Reads ideathon-related org settings.
abstract final class IdeathonSettingsService {
  IdeathonSettingsService._();

  static Future<void> ensureLoaded({required String orgId}) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
  }

  static int minIdeasRequiredForIdeathon(String orgId) {
    final Object? raw = OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.minIdeasRequiredForIdeathon];
    if (raw is int) return raw.clamp(1, 500);
    if (raw is num) return raw.round().clamp(1, 500);
    return 10;
  }

  static double prototypeSelectionThresholdPercent(String orgId) {
    final Object? raw = OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.prototypeSelectionThreshold];
    if (raw is int) return raw.clamp(0, 100).toDouble();
    if (raw is num) return raw.toDouble().clamp(0, 100);
    return 80;
  }

  static String ideathonEvaluationTemplateId(String orgId) {
    final String configured = OrgSettingsService.instance.ideathonEvaluationTemplateId.trim();
    if (configured.isNotEmpty) return configured;
    return DefaultEvaluationTemplateIds.ideathon;
  }

  static String ideaEvaluationTemplateId(String orgId) {
    return EvaluationTemplatesService.defaultTemplate.templateId;
  }
}
