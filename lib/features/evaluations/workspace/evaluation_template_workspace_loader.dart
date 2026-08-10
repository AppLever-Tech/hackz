import '../../org_settings/services/org_settings_service.dart';
import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';
import '../services/evaluation_template_helpers.dart';
import '../services/evaluation_templates_service.dart';

class EvaluationTemplateWorkspaceViewModel {
  const EvaluationTemplateWorkspaceViewModel({
    required this.template,
    required this.criteriaCount,
    required this.orgCriteria,
    required this.departmentCriteria,
    required this.weightLabelsByCriterionId,
    required this.totalWeight,
  });

  final EvaluationTemplate template;
  final int criteriaCount;
  final List<EvaluationCriterion> orgCriteria;
  final List<EvaluationCriterion> departmentCriteria;

  /// Precomputed weight labels (e.g. `20%`) keyed by criterion id.
  final Map<String, String> weightLabelsByCriterionId;

  /// Sum of positive criterion weights (for distribution bars).
  final double totalWeight;

  String get templateName {
    final String name = template.templateName.trim();
    return name.isEmpty ? 'Evaluation template' : name;
  }

  String get description => (template.description ?? '').trim();

  bool get hasDepartmentSections => departmentCriteria.isNotEmpty;

  String get statusLabel {
    if (!template.active) return 'Inactive';
    if (template.isDefault) return 'Default';
    return 'Active';
  }

  bool get isActive => template.active;
}

abstract final class EvaluationTemplateWorkspaceLoader {
  static Future<EvaluationTemplateWorkspaceViewModel> load(
    String templateId, {
    String? orgId,
    String? departmentCode,
  }) async {
    final String id = templateId.trim();
    if (id.isEmpty) {
      throw ArgumentError('templateId must be non-empty');
    }

    final String resolvedOrg =
        (orgId ?? OrgSettingsService.instance.currentOrgId ?? '').trim();
    if (resolvedOrg.isNotEmpty) {
      await OrgSettingsService.instance.ensureLoaded(orgId: resolvedOrg);
    }

    EvaluationTemplate? template = EvaluationTemplatesService.findTemplate(id);
    if (template == null) {
      throw StateError('Evaluation template not found');
    }

    final String dept = (departmentCode ?? '').trim().toUpperCase();
    if (dept.isNotEmpty) {
      template = template.withDepartmentExtensions(
        departmentCode: dept,
        extensions: EvaluationTemplatesService.departmentExtensionCriteriaForTemplate(
          departmentCode: dept,
          templateId: template.templateId,
        ),
      );
    }

    final List<EvaluationCriterion> ordered = template.orderedCriteria;
    final Map<String, String> weightLabels = <String, String>{
      for (final EvaluationCriterion c in ordered)
        c.criterionId: EvaluationTemplateHelpers.weightLabel(c, template),
    };

    double totalWeight = 0;
    for (final EvaluationCriterion c in ordered) {
      if (c.weight > 0) totalWeight += c.weight;
    }

    return EvaluationTemplateWorkspaceViewModel(
      template: template,
      criteriaCount: ordered.length,
      orgCriteria: template.orgCriteria,
      departmentCriteria: template.departmentExtensionCriteria,
      weightLabelsByCriterionId: weightLabels,
      totalWeight: totalWeight,
    );
  }
}
