import '../../evaluations/models/evaluation_template.dart';
import '../../evaluations/constants/default_evaluation_templates.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../../events/models/event_kind.dart';
import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';

/// Reads ideathon-related org settings.
abstract final class IdeathonSettingsService {
  IdeathonSettingsService._();

  static const int defaultMinimumIdeasForIdeathon = 10;

  static Future<void> ensureLoaded({required String orgId}) async {
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
  }

  static int minimumIdeasForIdeathon(String orgId) {
    final Object? raw = OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.minimumIdeasForIdeathon];
    if (raw is int) return raw.clamp(1, 500);
    if (raw is num) return raw.round().clamp(1, 500);
    return defaultMinimumIdeasForIdeathon;
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

  /// Default rubric for a new event. Research Paper uses Research & Publication.
  static String defaultEvaluationTemplateId({
    required String orgId,
    required EventKind eventKind,
  }) {
    if (eventKind == EventKind.researchPaper) {
      return _researchPublicationTemplateId();
    }
    return ideathonEvaluationTemplateId(orgId);
  }

  static String _researchPublicationTemplateId() {
    const String id = DefaultEvaluationTemplateIds.research;
    final List<EvaluationTemplate> active = EvaluationTemplatesService.activeTemplates;
    for (final EvaluationTemplate t in active) {
      if (t.templateId == id) return t.templateId;
    }
    for (final EvaluationTemplate t in active) {
      final String name = t.templateName.toLowerCase();
      if (name.contains('research') && name.contains('publication')) return t.templateId;
    }
    return id;
  }

  static String ideaEvaluationTemplateId(String orgId) {
    return EvaluationTemplatesService.defaultTemplate.templateId;
  }
}
