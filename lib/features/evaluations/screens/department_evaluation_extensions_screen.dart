import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../user/models/user_model.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';
import '../services/evaluation_templates_service.dart';

/// Department Admin workspace to extend (not replace) org evaluation criteria.
class DepartmentEvaluationExtensionsScreen extends StatefulWidget {
  const DepartmentEvaluationExtensionsScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  State<DepartmentEvaluationExtensionsScreen> createState() =>
      _DepartmentEvaluationExtensionsScreenState();
}

class _DepartmentEvaluationExtensionsScreenState
    extends State<DepartmentEvaluationExtensionsScreen> {
  late String _selectedTemplateId;
  bool _saving = false;
  bool _settingsReady = false;
  String? _settingsLoadError;

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = EvaluationTemplatesService.defaultTemplate.templateId;
    _ensureSettingsLoaded();
  }

  Future<void> _ensureSettingsLoaded() async {
    try {
      await OrgSettingsService.instance.ensureLoaded(orgId: widget.user.orgId);
      if (!mounted) return;
      setState(() {
        _settingsReady = true;
        _settingsLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settingsReady = false;
        _settingsLoadError = e.toString();
      });
    }
  }

  String get _departmentCode => widget.user.departmentCode.trim().toUpperCase();

  List<EvaluationTemplate> get _templates =>
      <EvaluationTemplate>[EvaluationTemplatesService.defaultTemplate];

  EvaluationTemplate get _selectedTemplate {
    for (final t in _templates) {
      if (t.templateId == _selectedTemplateId) return t;
    }
    return EvaluationTemplatesService.defaultTemplate;
  }

  Map<String, dynamic> get _selectedTemplateRaw {
    for (final m in EvaluationTemplatesService.templates.map((t) => t.toMap())) {
      if ((m['templateId'] as String?) == _selectedTemplate.templateId) return m;
    }
    for (final m in OrgSettingsService.instance.evaluationTemplatesRaw) {
      if (((m['templateId'] as String?) ?? '').trim() == _selectedTemplate.templateId) {
        return m;
      }
    }
    return const <String, dynamic>{};
  }

  List<EvaluationCriterion> get _extensions =>
      EvaluationTemplatesService.departmentExtensionCriteriaForTemplate(
        departmentCode: _departmentCode,
        templateId: _selectedTemplate.templateId,
      );

  Future<void> _save(List<EvaluationCriterion> next) async {
    if (!_settingsReady) {
      await _ensureSettingsLoaded();
      if (!_settingsReady) {
        if (!mounted) return;
        FeedbackService.showError(
          context,
          title: 'Settings unavailable',
          message: _settingsLoadError ?? 'Org settings not loaded.',
        );
        return;
      }
    }
    setState(() => _saving = true);
    final err = await EvaluationTemplatesService.saveDepartmentExtensionCriteria(
      departmentCode: _departmentCode,
      templateId: _selectedTemplate.templateId,
      criteria: next,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      FeedbackService.showError(
        context,
        title: 'Save failed',
        message: err,
      );
      return;
    }
    FeedbackService.showSuccess(
      context,
      title: 'Saved',
      message: 'Department evaluation extensions updated.',
    );
    setState(() {});
  }

  Future<void> _addCriterion() async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final weightCtl = TextEditingController(text: '1');
    final minCtl = TextEditingController(text: '1');
    final maxCtl = TextEditingController(text: '${_selectedTemplate.scoringScale}');
    bool commentsEnabled = false;

    final created = await showAppDialog<EvaluationCriterion>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Add department criterion',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                controller: descCtl,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Explain what judges should assess for this criterion.',
                ),
              ),
              TextField(
                controller: weightCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  hintText: 'e.g. 20% or 0.20 or 1.0',
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: minCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(labelText: 'Min score'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: maxCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(labelText: 'Max score'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                value: commentsEnabled,
                onChanged: (v) => setState(() => commentsEnabled = v),
                title: const Text('Allow per-criterion comments'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final title = titleCtl.text.trim();
                      if (title.isEmpty) return;
                      final String rawWeight = weightCtl.text.trim();
                      double parsedWeight = 1;
                      if (rawWeight.endsWith('%')) {
                        final numPart =
                            rawWeight.substring(0, rawWeight.length - 1).trim();
                        parsedWeight = (double.tryParse(numPart) ?? 100) / 100;
                      } else {
                        parsedWeight = double.tryParse(rawWeight) ?? 1;
                      }
                      final nextIndex = _extensions.length + 1;
                      final criterion = EvaluationCriterion(
                        criterionId:
                            'dept_${_departmentCode.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        description: descCtl.text.trim(),
                        weight: parsedWeight,
                        minScore: int.tryParse(minCtl.text.trim()) ?? 1,
                        maxScore: int.tryParse(maxCtl.text.trim()) ??
                            _selectedTemplate.scoringScale,
                        commentsEnabled: commentsEnabled,
                        displayOrder: nextIndex,
                        sourceType: EvaluationCriterionSourceType.department,
                        ownerDepartmentCode: _departmentCode,
                      );
                      Navigator.of(context).pop(criterion);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    titleCtl.dispose();
    descCtl.dispose();
    weightCtl.dispose();
    minCtl.dispose();
    maxCtl.dispose();
    if (created == null) return;
    final next = <EvaluationCriterion>[..._extensions, created];
    await _save(next);
  }

  Future<void> _deleteCriterion(EvaluationCriterion c) async {
    final ok = await FeedbackService.showConfirmation(
      context,
      title: 'Delete department criterion?',
      message: 'Remove "${c.title}" from this department extension?',
      confirmLabel: 'Delete',
      dangerConfirm: true,
    );
    if (!ok) return;
    await _save(_extensions.where((e) => e.criterionId != c.criterionId).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    final template = _selectedTemplate;
    final orgCriteria = template.orgCriteria;
    final ext = _extensions;
    final String templateLastUpdated = _templateLastUpdatedLabel(_selectedTemplateRaw);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!_settingsReady) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: <Widget>[
                      if (_settingsLoadError == null)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(AppIcons.error,
                            size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _settingsLoadError == null
                              ? 'Loading organization settings...'
                              : 'Unable to load organization settings.',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569)),
                        ),
                      ),
                      if (_settingsLoadError != null)
                        TextButton(
                          onPressed: _ensureSettingsLoaded,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Default Organization Template',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: EntityCardPills.workspace(
                                  template.templateName,
                                  ContextPillSemantic.evaluationTemplate,
                                  () => WorkspaceNavigator.openEvaluationTemplate(
                                    context,
                                    template.templateId,
                                    departmentCode: _departmentCode,
                                  ),
                                  icon: AppIcons.scoring,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: (_saving || !_settingsReady) ? null : _addCriterion,
                          icon: const Icon(AppIcons.add, size: 16),
                          label: const Text('Add Extension'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _metaChip('Criteria', '${orgCriteria.length}'),
                        if (templateLastUpdated != '—')
                          _metaChip('Last updated', templateLastUpdated),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Department-Specific Criteria',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (ext.isEmpty)
                      const Text('No department extension criteria added yet.',
                          style: TextStyle(color: Color(0xFF64748B)))
                    else
                      for (final c in ext) _buildDepartmentCriterionRow(c),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Organization Evaluation Criteria (Inherited)',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    for (final c in orgCriteria) _buildInheritedCriterionRow(c),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInheritedCriterionRow(EvaluationCriterion c) {
    final String description = c.description?.trim() ?? '';
    final String weightPct =
        '${(c.weight * 100).toStringAsFixed(c.weight * 100 >= 10 ? 0 : 1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(AppIcons.lock,
                size: 16, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    '• $description',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                _metaChip('Min', '${c.minScore}'),
                _metaChip('Max', '${c.maxScore}'),
                _metaChip('Weight', weightPct),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCriterionRow(EvaluationCriterion c) {
    final String description = c.description?.trim() ?? '';
    final String weightPct =
        '${(c.weight * 100).toStringAsFixed(c.weight * 100 >= 10 ? 0 : 1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              AppIcons.insights,
              size: 16,
              color: Color(0xFF6A38FF),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    '• $description',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                _metaChip('Min', '${c.minScore}'),
                _metaChip('Max', '${c.maxScore}'),
                _metaChip('Weight', weightPct),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Delete criterion',
            visualDensity: VisualDensity.compact,
            onPressed: _saving ? null : () => _deleteCriterion(c),
            icon: const Icon(AppIcons.remove, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  static Widget _metaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          children: <InlineSpan>[
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(
                text: value, style: const TextStyle(color: Color(0xFF334155))),
          ],
        ),
      ),
    );
  }

  static String _templateLastUpdatedLabel(Map<String, dynamic> raw) {
    final dynamic updatedAt = raw['updatedAt'];
    DateTime? dt;
    if (updatedAt is Timestamp) {
      dt = updatedAt.toDate();
    } else if (updatedAt is String) {
      dt = DateTime.tryParse(updatedAt);
    } else if (updatedAt is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(updatedAt);
    }
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

}
