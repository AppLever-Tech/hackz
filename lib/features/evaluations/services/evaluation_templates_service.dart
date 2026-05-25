import '../../org_settings/services/org_settings_service.dart';
import '../constants/default_evaluation_templates.dart';
import '../models/evaluation_template.dart';

/// Typed read/write facade over the evaluation templates list stored inside
/// `org_settings.evaluationTemplates`.
///
/// This service is stateless — it always reads from / writes to the
/// authoritative cache on [OrgSettingsService]. All mutation flows through
/// [OrgSettingsService.updateEvaluationTemplates] so cache and Firestore stay
/// in lock-step.
abstract final class EvaluationTemplatesService {
  EvaluationTemplatesService._();

  /// Decodes the current raw template list from [OrgSettingsService] into
  /// typed [EvaluationTemplate]s.
  static List<EvaluationTemplate> get templates {
    final List<Map<String, dynamic>> raw =
        OrgSettingsService.instance.evaluationTemplatesRaw;
    return raw
        .map((Map<String, dynamic> m) => EvaluationTemplate.fromMap(m))
        .toList(growable: false);
  }

  /// Returns active templates only. Used by the judge UI to populate the
  /// "which template" picker (only the default is used today, but keeping
  /// this filter ready makes future event/round-based assignment cheap).
  static List<EvaluationTemplate> get activeTemplates =>
      templates.where((EvaluationTemplate t) => t.active).toList(growable: false);

  /// Returns the default template (first active `isDefault == true`).
  ///
  /// Falls back to the first active template, then to the in-Dart Ideathon
  /// default. Never returns `null` so the judge UI can always render.
  static EvaluationTemplate get defaultTemplate {
    final List<EvaluationTemplate> all = templates;
    for (final EvaluationTemplate t in all) {
      if (t.isDefault && t.active) return t;
    }
    for (final EvaluationTemplate t in all) {
      if (t.active) return t;
    }
    if (all.isNotEmpty) return all.first;
    return defaultEvaluationTemplates.first;
  }

  /// Looks up a template by id. Falls back to [defaultTemplate] when not
  /// found so legacy/orphan score documents still render gracefully.
  static EvaluationTemplate resolveTemplate(String? templateId) {
    final String id = (templateId ?? '').trim();
    if (id.isEmpty) return defaultTemplate;
    for (final EvaluationTemplate t in templates) {
      if (t.templateId == id) return t;
    }
    return defaultTemplate;
  }

  /// Persists a full replacement of the templates list.
  ///
  /// The caller is responsible for invariants: exactly one `isDefault: true`,
  /// no duplicate `templateId`s, criteria have unique `criterionId`s within a
  /// template. Returns an error string on failure.
  static Future<String?> saveTemplates(List<EvaluationTemplate> next) {
    final List<EvaluationTemplate> normalized = _normalize(next);
    return OrgSettingsService.instance.updateEvaluationTemplates(
      normalized.map((EvaluationTemplate t) => t.toMap()).toList(growable: false),
    );
  }

  /// Normalizes a list so exactly one template carries `isDefault: true`.
  /// If multiple are flagged, the first one wins. If none are flagged, the
  /// first active template is promoted; if there are no active templates the
  /// list is returned unchanged.
  static List<EvaluationTemplate> _normalize(List<EvaluationTemplate> input) {
    if (input.isEmpty) return input;
    int defaultIdx = -1;
    for (int i = 0; i < input.length; i++) {
      if (input[i].isDefault && input[i].active) {
        defaultIdx = i;
        break;
      }
    }
    if (defaultIdx == -1) {
      for (int i = 0; i < input.length; i++) {
        if (input[i].active) {
          defaultIdx = i;
          break;
        }
      }
    }
    if (defaultIdx == -1) {
      return input.map((EvaluationTemplate t) => t.copyWith(isDefault: false)).toList(growable: false);
    }
    return List<EvaluationTemplate>.generate(input.length, (int i) {
      return input[i].copyWith(isDefault: i == defaultIdx);
    });
  }
}
