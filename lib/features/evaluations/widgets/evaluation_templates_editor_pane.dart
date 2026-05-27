import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../responsive/responsive_helper.dart';
import '../../../shared/feedback/feedback.dart';
import '../../org_settings/widgets/settings_group_widget.dart';
import '../../org_settings/widgets/settings_number_stepper.dart';
import '../../org_settings/widgets/settings_switch_tile.dart';
import '../../org_settings/widgets/settings_tile.dart';
import '../models/evaluation_criterion.dart';
import '../models/evaluation_template.dart';
import '../services/evaluation_templates_service.dart';

/// College Admin editor for evaluation templates.
///
/// Lives inside `OrgSettingsDashboard`'s right pane when the
/// "Evaluation templates" section is selected. Reuses the standard
/// `SettingsGroupWidget`/`SettingsTile`/`SettingsSwitchTile`/`SettingsNumberStepper`
/// vocabulary so it looks like a natural extension of the rest of the page.
class EvaluationTemplatesEditorPane extends StatefulWidget {
  const EvaluationTemplatesEditorPane({super.key});

  @override
  State<EvaluationTemplatesEditorPane> createState() => _EvaluationTemplatesEditorPaneState();
}

class _EvaluationTemplatesEditorPaneState extends State<EvaluationTemplatesEditorPane> {
  /// Working copy. We never mutate the service-resolved list directly so
  /// users can discard drafts cleanly.
  List<_TemplateDraft> _drafts = <_TemplateDraft>[];
  String? _selectedId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resetFromService();
  }

  void _resetFromService() {
    final List<EvaluationTemplate> live = EvaluationTemplatesService.templates;
    setState(() {
      _drafts = live.map(_TemplateDraft.from).toList(growable: true);
      _selectedId = _drafts.isEmpty
          ? null
          : (_drafts.firstWhere(
              (_TemplateDraft d) => d.isDefault,
              orElse: () => _drafts.first,
            )).templateId;
    });
  }

  _TemplateDraft? get _selected {
    final String? id = _selectedId;
    if (id == null) return null;
    for (final _TemplateDraft d in _drafts) {
      if (d.templateId == id) return d;
    }
    return _drafts.isEmpty ? null : _drafts.first;
  }

  bool get _dirty {
    final List<EvaluationTemplate> live = EvaluationTemplatesService.templates;
    if (live.length != _drafts.length) return true;
    final Map<String, EvaluationTemplate> liveById = <String, EvaluationTemplate>{
      for (final EvaluationTemplate t in live) t.templateId: t,
    };
    for (int i = 0; i < _drafts.length; i++) {
      final _TemplateDraft d = _drafts[i];
      final EvaluationTemplate? prev = liveById[d.templateId];
      if (prev == null) return true;
      if (!_draftEqualsTemplate(d, prev)) return true;
    }
    return false;
  }

  String? _validate() {
    if (_drafts.isEmpty) return 'At least one template is required.';
    final Set<String> ids = <String>{};
    int defaults = 0;
    for (final _TemplateDraft d in _drafts) {
      if (d.templateId.trim().isEmpty) return 'Template id cannot be empty.';
      if (!ids.add(d.templateId)) return 'Duplicate template id: ${d.templateId}';
      if (d.templateName.trim().isEmpty) return 'Template name cannot be empty.';
      if (d.criteria.isEmpty) return '${d.templateName}: at least one criterion is required.';
      if (d.isDefault) defaults++;
      final Set<String> critIds = <String>{};
      for (final _CriterionDraft c in d.criteria) {
        if (c.criterionId.trim().isEmpty) return '${d.templateName}: criterion id cannot be empty.';
        if (!critIds.add(c.criterionId)) {
          return '${d.templateName}: duplicate criterion id "${c.criterionId}".';
        }
        if (c.title.trim().isEmpty) return '${d.templateName}: criterion title cannot be empty.';
        if (c.minScore >= c.maxScore) {
          return '${d.templateName} / ${c.title}: minScore must be less than maxScore.';
        }
      }
    }
    if (defaults != 1) return 'Exactly one template must be marked default.';
    return null;
  }

  Future<void> _save() async {
    final String? validation = _validate();
    if (validation != null) {
      FeedbackService.showWarning(
        context,
        title: 'Template validation failed',
        message: validation,
      );
      return;
    }
    setState(() => _saving = true);
    final List<EvaluationTemplate> next = _drafts
        .map((_TemplateDraft d) => d.toTemplate())
        .toList(growable: false);
    final String? err = await EvaluationTemplatesService.saveTemplates(next);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      FeedbackService.showError(
        context,
        title: 'Save failed',
        message: err,
      );
    } else {
      FeedbackService.showSuccess(
        context,
        title: 'Saved',
        message: 'Evaluation templates saved.',
      );
      _resetFromService();
    }
  }

  void _addTemplate() {
    final String id = _suggestUniqueId('template', _drafts.map((d) => d.templateId).toSet());
    final _TemplateDraft draft = _TemplateDraft(
      templateId: id,
      templateName: 'New template',
      description: '',
      scoringScale: 10,
      isDefault: false,
      active: true,
      criteria: <_CriterionDraft>[
        _CriterionDraft(
          criterionId: 'overall',
          title: 'Overall',
          description: '',
          weight: 1.0,
          minScore: 1,
          maxScore: 10,
          commentsEnabled: false,
          displayOrder: 1,
        ),
      ],
    );
    setState(() {
      _drafts.add(draft);
      _selectedId = id;
    });
  }

  void _deleteTemplate(_TemplateDraft target) {
    if (_drafts.length <= 1) {
      FeedbackService.showWarning(
        context,
        title: 'Cannot delete template',
        message: 'At least one template is required.',
      );
      return;
    }
    setState(() {
      _drafts.removeWhere((_TemplateDraft d) => d.templateId == target.templateId);
      if (target.isDefault && _drafts.isNotEmpty) {
        _drafts[0] = _drafts[0].copyWith(isDefault: true);
      }
      _selectedId = _drafts.first.templateId;
    });
  }

  void _setDefault(_TemplateDraft target) {
    setState(() {
      for (int i = 0; i < _drafts.length; i++) {
        _drafts[i] = _drafts[i].copyWith(isDefault: _drafts[i].templateId == target.templateId);
      }
    });
  }

  void _updateSelected(_TemplateDraft Function(_TemplateDraft) updater) {
    final _TemplateDraft? curr = _selected;
    if (curr == null) return;
    setState(() {
      final int idx = _drafts.indexWhere((_TemplateDraft d) => d.templateId == curr.templateId);
      if (idx == -1) return;
      _drafts[idx] = updater(_drafts[idx]);
      _selectedId = _drafts[idx].templateId;
    });
  }

  String _suggestUniqueId(String base, Set<String> taken) {
    final String slug = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isEmpty) return 'template_${DateTime.now().millisecondsSinceEpoch}';
    if (!taken.contains(slug)) return slug;
    int n = 2;
    while (taken.contains('${slug}_$n')) {
      n++;
    }
    return '${slug}_$n';
  }

  @override
  Widget build(BuildContext context) {
    final _TemplateDraft? selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeader(context),
        const SizedBox(height: 10),
        if (selected == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: Text('No templates configured.')),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 24),
              children: _buildTemplateBlocks(context, selected),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final List<Widget> chips = <Widget>[
      for (final _TemplateDraft d in _drafts) _buildTemplateChip(context, d),
      _buildAddChip(context),
    ];

    final bool mobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.scoring, size: 18, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Templates',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (!mobile) ...<Widget>[
                FilledButton.icon(
                  onPressed: (_saving || !_dirty) ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, size: 16),
                  label: Text(_saving ? 'Saving' : 'Save templates'),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: (_saving || !_dirty) ? null : _resetFromService,
                  icon: const Icon(AppIcons.remove, size: 16),
                  label: const Text('Discard'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips,
          ),
          if (mobile) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_saving || !_dirty) ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 16),
                    label: Text(_saving ? 'Saving' : 'Save'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_saving || !_dirty) ? null : _resetFromService,
                    icon: const Icon(AppIcons.remove, size: 16),
                    label: const Text('Discard'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateChip(BuildContext context, _TemplateDraft d) {
    final bool selected = d.templateId == _selectedId;
    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            d.templateName.trim().isEmpty ? d.templateId : d.templateName.trim(),
            style: TextStyle(fontWeight: selected ? FontWeight.w900 : FontWeight.w700, fontSize: 12),
          ),
          if (d.isDefault) ...<Widget>[
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
          ],
          if (!d.active) ...<Widget>[
            const SizedBox(width: 4),
            const Icon(Icons.visibility_off_outlined, size: 12, color: Color(0xFF94A3B8)),
          ],
        ],
      ),
      selected: selected,
      showCheckmark: false,
      onPressed: () => setState(() => _selectedId = d.templateId),
      backgroundColor: const Color(0xFFF1F5F9),
      selectedColor: const Color(0xFFE0E7FF),
      side: BorderSide(color: selected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1), width: selected ? 1.4 : 1),
    );
  }

  Widget _buildAddChip(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF6366F1)),
      label: const Text('Add template', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF6366F1))),
      onPressed: _saving ? null : _addTemplate,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF93C5FD)),
    );
  }

  List<Widget> _buildTemplateBlocks(BuildContext context, _TemplateDraft selected) {
    return <Widget>[
      SettingsGroupWidget(
        title: 'Template details',
        children: <Widget>[
          _textRow(
            label: 'Name',
            value: selected.templateName,
            onChanged: (String s) => _updateSelected((d) => d.copyWith(templateName: s)),
            hint: 'e.g. College Ideathon Evaluation',
          ),
          _textRow(
            label: 'Description',
            value: selected.description,
            onChanged: (String s) => _updateSelected((d) => d.copyWith(description: s)),
            hint: 'Optional short summary',
            maxLines: 2,
          ),
          SettingsTile(
            title: 'Scoring scale',
            subtitle: 'Upper bound used when judges see the overall score.',
            trailing: SettingsNumberStepper(
              value: selected.scoringScale,
              min: 5,
              max: 20,
              step: 1,
              onChanged: (int v) => _updateSelected((d) => d.copyWith(scoringScale: v)),
            ),
          ),
          SettingsSwitchTile(
            title: 'Active',
            subtitle: 'Inactive templates stay readable for historical scores but cannot be picked for new evaluations.',
            value: selected.active,
            onChanged: (bool v) => _updateSelected((d) => d.copyWith(active: v)),
          ),
          SettingsTile(
            title: 'Default template',
            subtitle: 'New evaluations start with the default. Exactly one template carries this flag.',
            trailing: selected.isDefault
                ? const _DefaultBadge()
                : OutlinedButton.icon(
                    onPressed: () => _setDefault(selected),
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text('Make default'),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _deleteTemplate(selected),
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                label: const Text('Delete template', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      SettingsGroupWidget(
        title: 'Criteria',
        children: <Widget>[
          for (int i = 0; i < selected.criteria.length; i++)
            _CriterionEditorCard(
              criterion: selected.criteria[i],
              index: i,
              total: selected.criteria.length,
              onChanged: (_CriterionDraft updated) {
                _updateSelected((d) {
                  final List<_CriterionDraft> next = List<_CriterionDraft>.from(d.criteria);
                  next[i] = updated;
                  return d.copyWith(criteria: next);
                });
              },
              onMoveUp: i == 0
                  ? null
                  : () {
                      _updateSelected((d) {
                        final List<_CriterionDraft> next = List<_CriterionDraft>.from(d.criteria);
                        final _CriterionDraft moved = next.removeAt(i);
                        next.insert(i - 1, moved);
                        return d.copyWith(criteria: _reindex(next));
                      });
                    },
              onMoveDown: i == selected.criteria.length - 1
                  ? null
                  : () {
                      _updateSelected((d) {
                        final List<_CriterionDraft> next = List<_CriterionDraft>.from(d.criteria);
                        final _CriterionDraft moved = next.removeAt(i);
                        next.insert(i + 1, moved);
                        return d.copyWith(criteria: _reindex(next));
                      });
                    },
              onRemove: selected.criteria.length <= 1
                  ? null
                  : () {
                      _updateSelected((d) {
                        final List<_CriterionDraft> next = List<_CriterionDraft>.from(d.criteria)..removeAt(i);
                        return d.copyWith(criteria: _reindex(next));
                      });
                    },
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                _updateSelected((d) {
                  final Set<String> taken = <String>{
                    for (final _CriterionDraft c in d.criteria) c.criterionId,
                  };
                  final String id = _suggestUniqueId('criterion', taken);
                  final List<_CriterionDraft> next = List<_CriterionDraft>.from(d.criteria);
                  next.add(
                    _CriterionDraft(
                      criterionId: id,
                      title: 'New criterion',
                      description: '',
                      weight: 1,
                      minScore: 1,
                      maxScore: d.scoringScale,
                      commentsEnabled: false,
                      displayOrder: next.length + 1,
                    ),
                  );
                  return d.copyWith(criteria: next);
                });
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add criterion'),
            ),
          ),
        ],
      ),
    ];
  }

  static List<_CriterionDraft> _reindex(List<_CriterionDraft> list) {
    return List<_CriterionDraft>.generate(
      list.length,
      (int i) => list[i].copyWith(displayOrder: i + 1),
    );
  }

  Widget _textRow({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            maxLines: maxLines,
            minLines: maxLines > 1 ? 1 : null,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.star_rounded, size: 14, color: Color(0xFFB45309)),
          SizedBox(width: 4),
          Text('Default', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
        ],
      ),
    );
  }
}

class _CriterionEditorCard extends StatelessWidget {
  const _CriterionEditorCard({
    required this.criterion,
    required this.index,
    required this.total,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final _CriterionDraft criterion;
  final int index;
  final int total;
  final ValueChanged<_CriterionDraft> onChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey<String>('title-${criterion.criterionId}'),
                  initialValue: criterion.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Criterion title',
                  ),
                  onChanged: (String s) => onChanged(criterion.copyWith(title: s)),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Move up',
                onPressed: onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Move down',
                onPressed: onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          TextFormField(
            key: ValueKey<String>('desc-${criterion.criterionId}'),
            initialValue: criterion.description,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Optional description shown to judges…',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onChanged: (String s) => onChanged(criterion.copyWith(description: s)),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final bool stack = c.maxWidth < 460;
              final Widget weightField = _WeightField(
                weight: criterion.weight,
                onChanged: (double w) => onChanged(criterion.copyWith(weight: w)),
              );
              final Widget minStepper = _LabeledStepper(
                label: 'Min',
                value: criterion.minScore,
                min: 0,
                max: criterion.maxScore - 1,
                onChanged: (int v) => onChanged(criterion.copyWith(minScore: v)),
              );
              final Widget maxStepper = _LabeledStepper(
                label: 'Max',
                value: criterion.maxScore,
                min: criterion.minScore + 1,
                max: 20,
                onChanged: (int v) => onChanged(criterion.copyWith(maxScore: v)),
              );
              final Widget commentsToggle = _CommentsToggle(
                enabled: criterion.commentsEnabled,
                onChanged: (bool v) => onChanged(criterion.copyWith(commentsEnabled: v)),
              );

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    weightField,
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(child: minStepper),
                        const SizedBox(width: 6),
                        Expanded(child: maxStepper),
                      ],
                    ),
                    const SizedBox(height: 8),
                    commentsToggle,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Expanded(flex: 3, child: weightField),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: minStepper),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: maxStepper),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: commentsToggle),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeightField extends StatelessWidget {
  const _WeightField({required this.weight, required this.onChanged});

  final double weight;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          const Text(
            'Weight',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey<String>('weight-${weight.toStringAsFixed(4)}'),
              initialValue: _formatWeight(weight),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (String s) {
                final double? parsed = double.tryParse(s.trim());
                if (parsed == null) return;
                if (parsed < 0) return;
                onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatWeight(double w) {
    if (w == w.roundToDouble()) return w.toStringAsFixed(0);
    return w.toStringAsFixed(2);
  }
}

class _LabeledStepper extends StatelessWidget {
  const _LabeledStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
        const SizedBox(width: 6),
        SettingsNumberStepper(
          value: value,
          min: min,
          max: max,
          step: 1,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CommentsToggle extends StatelessWidget {
  const _CommentsToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              'Comments',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeColor: const Color(0xFF6A38FF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TemplateDraft {
  _TemplateDraft({
    required this.templateId,
    required this.templateName,
    required this.description,
    required this.scoringScale,
    required this.isDefault,
    required this.active,
    required this.criteria,
  });

  final String templateId;
  String templateName;
  String description;
  int scoringScale;
  bool isDefault;
  bool active;
  List<_CriterionDraft> criteria;

  factory _TemplateDraft.from(EvaluationTemplate t) {
    return _TemplateDraft(
      templateId: t.templateId,
      templateName: t.templateName,
      description: t.description ?? '',
      scoringScale: t.scoringScale,
      isDefault: t.isDefault,
      active: t.active,
      criteria: t.orderedCriteria
          .map((EvaluationCriterion c) => _CriterionDraft.from(c))
          .toList(growable: true),
    );
  }

  _TemplateDraft copyWith({
    String? templateName,
    String? description,
    int? scoringScale,
    bool? isDefault,
    bool? active,
    List<_CriterionDraft>? criteria,
  }) {
    return _TemplateDraft(
      templateId: templateId,
      templateName: templateName ?? this.templateName,
      description: description ?? this.description,
      scoringScale: scoringScale ?? this.scoringScale,
      isDefault: isDefault ?? this.isDefault,
      active: active ?? this.active,
      criteria: criteria ?? this.criteria,
    );
  }

  EvaluationTemplate toTemplate() {
    return EvaluationTemplate(
      templateId: templateId.trim(),
      templateName: templateName.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      scoringScale: scoringScale,
      criteria: criteria.map((_CriterionDraft c) => c.toCriterion()).toList(growable: false),
      isDefault: isDefault,
      active: active,
    );
  }
}

class _CriterionDraft {
  _CriterionDraft({
    required this.criterionId,
    required this.title,
    required this.description,
    required this.weight,
    required this.minScore,
    required this.maxScore,
    required this.commentsEnabled,
    required this.displayOrder,
  });

  final String criterionId;
  String title;
  String description;
  double weight;
  int minScore;
  int maxScore;
  bool commentsEnabled;
  int displayOrder;

  factory _CriterionDraft.from(EvaluationCriterion c) {
    return _CriterionDraft(
      criterionId: c.criterionId,
      title: c.title,
      description: c.description ?? '',
      weight: c.weight,
      minScore: c.minScore,
      maxScore: c.maxScore,
      commentsEnabled: c.commentsEnabled,
      displayOrder: c.displayOrder,
    );
  }

  _CriterionDraft copyWith({
    String? title,
    String? description,
    double? weight,
    int? minScore,
    int? maxScore,
    bool? commentsEnabled,
    int? displayOrder,
  }) {
    return _CriterionDraft(
      criterionId: criterionId,
      title: title ?? this.title,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      minScore: minScore ?? this.minScore,
      maxScore: maxScore ?? this.maxScore,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  EvaluationCriterion toCriterion() {
    return EvaluationCriterion(
      criterionId: criterionId.trim(),
      title: title.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      weight: weight,
      minScore: minScore,
      maxScore: maxScore,
      commentsEnabled: commentsEnabled,
      displayOrder: displayOrder,
    );
  }
}

bool _draftEqualsTemplate(_TemplateDraft d, EvaluationTemplate t) {
  if (d.templateName.trim() != t.templateName.trim()) return false;
  if ((d.description.trim().isEmpty ? null : d.description.trim()) != t.description) return false;
  if (d.scoringScale != t.scoringScale) return false;
  if (d.isDefault != t.isDefault) return false;
  if (d.active != t.active) return false;
  final List<EvaluationCriterion> orderedT = t.orderedCriteria;
  if (d.criteria.length != orderedT.length) return false;
  for (int i = 0; i < d.criteria.length; i++) {
    final _CriterionDraft a = d.criteria[i];
    final EvaluationCriterion b = orderedT[i];
    if (a.criterionId != b.criterionId) return false;
    if (a.title.trim() != b.title.trim()) return false;
    if ((a.description.trim().isEmpty ? null : a.description.trim()) != b.description) return false;
    if (a.weight != b.weight) return false;
    if (a.minScore != b.minScore) return false;
    if (a.maxScore != b.maxScore) return false;
    if (a.commentsEnabled != b.commentsEnabled) return false;
    if (a.displayOrder != b.displayOrder) return false;
  }
  return true;
}
