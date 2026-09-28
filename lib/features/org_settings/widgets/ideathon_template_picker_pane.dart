import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../evaluations/models/evaluation_template.dart';
import '../../evaluations/services/evaluation_templates_service.dart';
import '../services/org_settings_service.dart';

/// Picks which evaluation template is used for ideathon events.
class IdeathonTemplatePickerPane extends StatefulWidget {
  const IdeathonTemplatePickerPane({super.key});

  @override
  State<IdeathonTemplatePickerPane> createState() => _IdeathonTemplatePickerPaneState();
}

class _IdeathonTemplatePickerPaneState extends State<IdeathonTemplatePickerPane> {
  String? _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedId = OrgSettingsService.instance.ideathonEvaluationTemplateId;
  }

  Future<void> _save() async {
    final String? id = _selectedId;
    if (id == null || id.trim().isEmpty) return;
    setState(() => _saving = true);
    final String? err = await OrgSettingsService.instance.updateIdeathonEvaluationTemplateId(id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      FeedbackService.showError(context, title: 'Save failed', message: err);
    } else {
      FeedbackService.showSuccess(context, title: 'Saved', message: 'Ideathon evaluation template updated.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<EvaluationTemplate> templates = EvaluationTemplatesService.activeTemplates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Ideathon evaluation template',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Judges use this rubric when scoring ideas during ideathon events.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        ...templates.map(
          (EvaluationTemplate template) => RadioListTile<String>(
            value: template.templateId,
            groupValue: _selectedId,
            onChanged: _saving
                ? null
                : (String? value) => setState(() => _selectedId = value),
            title: Align(
              alignment: Alignment.centerLeft,
              child: EntityCardPills.workspace(
                template.templateName,
                ContextPillSemantic.evaluationTemplate,
                () => WorkspaceNavigator.openEvaluationTemplate(context, template.templateId),
                icon: AppIcons.scoring,
              ),
            ),
            subtitle: Text(
              (template.description ?? '').trim().isEmpty
                  ? template.templateId
                  : (template.description ?? '').trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save template'),
          ),
        ),
      ],
    );
  }
}
