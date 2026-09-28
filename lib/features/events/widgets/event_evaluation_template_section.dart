import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../evaluations/models/evaluation_criterion.dart';
import '../../evaluations/models/evaluation_template.dart';
import '../../evaluations/services/evaluation_template_helpers.dart';
import '../../evaluations/widgets/evaluation_criterion_editor_dialog.dart';
import 'event_detail_section.dart';
import 'event_meta_chip.dart';

/// Event-generic evaluation template workspace (Ideathon today; Hackathon later).
class EventEvaluationTemplateSection extends StatefulWidget {
  const EventEvaluationTemplateSection({
    super.key,
    required this.template,
    required this.departmentCode,
    required this.locked,
    required this.canManage,
    required this.onSave,
    this.lockedMessage = '',
  });

  final EvaluationTemplate template;
  final String departmentCode;
  final bool locked;
  final bool canManage;
  final String lockedMessage;
  final Future<void> Function(List<EvaluationCriterion> criteria) onSave;

  @override
  State<EventEvaluationTemplateSection> createState() =>
      _EventEvaluationTemplateSectionState();
}

class _EventEvaluationTemplateSectionState extends State<EventEvaluationTemplateSection> {
  late List<EvaluationCriterion> _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = List<EvaluationCriterion>.from(widget.template.orderedCriteria);
  }

  @override
  void didUpdateWidget(covariant EventEvaluationTemplateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_criteriaEqual(oldWidget.template.orderedCriteria, widget.template.orderedCriteria)) {
      _draft = List<EvaluationCriterion>.from(widget.template.orderedCriteria);
    }
  }

  static bool _criteriaEqual(List<EvaluationCriterion> a, List<EvaluationCriterion> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final EvaluationCriterion x = a[i];
      final EvaluationCriterion y = b[i];
      if (x.criterionId != y.criterionId ||
          x.title != y.title ||
          (x.description ?? '') != (y.description ?? '') ||
          x.weight != y.weight ||
          x.minScore != y.minScore ||
          x.maxScore != y.maxScore ||
          x.sourceType != y.sourceType) {
        return false;
      }
    }
    return true;
  }

  bool get _editable => widget.canManage && !widget.locked && !_saving;

  int get _total => EvaluationTemplateHelpers.totalWeightPercentRounded(_draft);

  bool get _complete => EvaluationTemplateHelpers.isTotalWeightComplete(_draft);

  String? get _weightError => EvaluationTemplateHelpers.validateWeights(_draft);

  bool get _dirty {
    if (_draft.length != widget.template.criteria.length) return true;
    for (int i = 0; i < _draft.length; i++) {
      final EvaluationCriterion a = _draft[i];
      EvaluationCriterion? b;
      for (final EvaluationCriterion c in widget.template.criteria) {
        if (c.criterionId == a.criterionId) {
          b = c;
          break;
        }
      }
      if (b == null) return true;
      if (a.title != b.title ||
          (a.description ?? '') != (b.description ?? '') ||
          a.weight != b.weight ||
          a.minScore != b.minScore ||
          a.maxScore != b.maxScore) {
        return true;
      }
    }
    final Set<String> draftIds = <String>{for (final EvaluationCriterion c in _draft) c.criterionId};
    for (final EvaluationCriterion c in widget.template.criteria) {
      if (!draftIds.contains(c.criterionId)) return true;
    }
    return false;
  }

  List<EvaluationCriterion> get _inherited => _draft
      .where((EvaluationCriterion c) => c.sourceType == EvaluationCriterionSourceType.org)
      .toList(growable: false);

  List<EvaluationCriterion> get _extensions => _draft
      .where((EvaluationCriterion c) => c.sourceType == EvaluationCriterionSourceType.department)
      .toList(growable: false);

  Future<void> _save() async {
    if (!_editable || !_complete) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(List<EvaluationCriterion>.from(_draft));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editCriterion(EvaluationCriterion criterion) async {
    if (!_editable) return;
    final bool inherited = criterion.sourceType == EvaluationCriterionSourceType.org;
    final int maxWeight = EvaluationTemplateHelpers.maxAssignablePercent(
      criteria: _draft,
      editing: criterion,
    );
    final EvaluationCriterionEditorResult? result = await showEvaluationCriterionEditor(
      context: context,
      title: inherited ? 'Edit inherited criterion' : 'Edit event criterion',
      existing: criterion,
      currentTotalPercent: _total,
      maxWeightPercent: maxWeight,
      scoringScale: widget.template.scoringScale,
      inherited: inherited,
    );
    if (result == null || !mounted) return;
    setState(() {
      _draft = _draft
          .map(
            (EvaluationCriterion c) => c.criterionId == criterion.criterionId
                ? c.copyWith(
                    title: result.title,
                    description: result.description,
                    weight: result.weightPercent / 100,
                    minScore: result.minScore,
                    maxScore: result.maxScore,
                  )
                : c,
          )
          .toList();
    });
  }

  Future<void> _addExtension() async {
    if (!_editable) return;
    final int remaining = EvaluationTemplateHelpers.remainingWeightPercent(_draft);
    if (remaining <= 0) return;
    final EvaluationCriterionEditorResult? result = await showEvaluationCriterionEditor(
      context: context,
      title: 'Add evaluation criterion',
      currentTotalPercent: _total,
      maxWeightPercent: remaining,
      scoringScale: widget.template.scoringScale,
    );
    if (result == null || !mounted) return;
    final String dept = widget.departmentCode.trim().toUpperCase();
    int nextOrder = _draft.isEmpty
        ? 1
        : _draft.map((EvaluationCriterion c) => c.displayOrder).reduce((int a, int b) => a > b ? a : b) + 1;
    setState(() {
      _draft = <EvaluationCriterion>[
        ..._draft,
        EvaluationCriterion(
          criterionId: 'dept_${dept.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
          title: result.title,
          description: result.description,
          weight: result.weightPercent / 100,
          minScore: result.minScore,
          maxScore: result.maxScore,
          displayOrder: nextOrder,
          sourceType: EvaluationCriterionSourceType.department,
          ownerDepartmentCode: dept,
        ),
      ];
    });
  }

  void _removeExtension(EvaluationCriterion criterion) {
    if (!_editable) return;
    if (criterion.sourceType != EvaluationCriterionSourceType.department) return;
    setState(() {
      _draft = _draft.where((EvaluationCriterion c) => c.criterionId != criterion.criterionId).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String templateName = widget.template.templateName.trim().isEmpty
        ? 'Evaluation Template'
        : widget.template.templateName.trim();
    final int remaining = 100 - _total;
    final Color totalColor = _total > 100
        ? const Color(0xFFB91C1C)
        : _total == 100
            ? const Color(0xFF047857)
            : const Color(0xFFB45309);
    final bool mobile = ResponsiveHelper.isMobile(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      children: <Widget>[
        _Header(
          templateName: templateName,
          description: (widget.template.description ?? '').trim(),
          locked: widget.locked,
          canManage: widget.canManage,
          lockedMessage: widget.lockedMessage,
        ),
        const SizedBox(height: 12),
        _WeightageBar(
          total: _total,
          remaining: remaining,
          color: totalColor,
          error: _weightError,
          dirty: _dirty,
          complete: _complete,
          saving: _saving,
          canSave: _editable && _dirty && _complete,
          onSave: _save,
          compact: mobile,
        ),
        const SizedBox(height: 12),
        EventDetailSection(
          title: 'Criteria',
          icon: AppIcons.checklist,
          titleFontSize: 13,
          titleFontWeight: FontWeight.w900,
          titleColor: const Color(0xFF0F172A),
          trailing: EventMetaChip(
            icon: AppIcons.copy,
            label: 'Inherited',
            color: const Color(0xFF4338CA),
          ),
          child: _inherited.isEmpty
              ? const Text(
                  'No inherited criteria on this template.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                )
              : Column(
                  children: <Widget>[
                    for (int i = 0; i < _inherited.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      _CriterionRow(
                        criterion: _inherited[i],
                        inherited: true,
                        editable: _editable,
                        onEdit: () => _editCriterion(_inherited[i]),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        EventDetailSection(
          title: 'Event Extensions',
          icon: AppIcons.add,
          titleFontSize: 13,
          titleFontWeight: FontWeight.w900,
          titleColor: const Color(0xFF0F172A),
          trailing: EventMetaChip(
            icon: AppIcons.scoring,
            label: 'Event-specific',
            color: const Color(0xFF0F766E),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_extensions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No event-specific criteria yet. Inherited criteria still apply.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                )
              else
                Column(
                  children: <Widget>[
                    for (int i = 0; i < _extensions.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      _CriterionRow(
                        criterion: _extensions[i],
                        inherited: false,
                        editable: _editable,
                        onEdit: () => _editCriterion(_extensions[i]),
                        onDelete: () => _removeExtension(_extensions[i]),
                      ),
                    ],
                  ],
                ),
              if (_editable) ...<Widget>[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: remaining <= 0 ? null : _addExtension,
                    icon: const Icon(AppIcons.add, size: 16),
                    label: const Text('Add Evaluation Criterion'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                if (remaining <= 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Reduce existing weightage before adding a criterion.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.templateName,
    required this.description,
    required this.locked,
    required this.canManage,
    required this.lockedMessage,
  });

  final String templateName;
  final String description;
  final bool locked;
  final bool canManage;
  final String lockedMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Evaluation Template',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Text(
            templateName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          if (description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              const EventMetaChip(icon: AppIcons.copy, label: 'Inherited', color: Color(0xFF4338CA)),
              if (locked)
                const EventMetaChip(icon: AppIcons.lock, label: 'Locked', color: Color(0xFFB45309))
              else if (canManage)
                const EventMetaChip(icon: AppIcons.edit, label: 'Editable', color: Color(0xFF047857))
              else
                const EventMetaChip(icon: AppIcons.preview, label: 'View only', color: Color(0xFF64748B)),
            ],
          ),
          if (locked && lockedMessage.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(AppIcons.lock, size: 15, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lockedMessage,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9A3412)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightageBar extends StatelessWidget {
  const _WeightageBar({
    required this.total,
    required this.remaining,
    required this.color,
    required this.error,
    required this.dirty,
    required this.complete,
    required this.saving,
    required this.canSave,
    required this.onSave,
    required this.compact,
  });

  final int total;
  final int remaining;
  final Color color;
  final String? error;
  final bool dirty;
  final bool complete;
  final bool saving;
  final bool canSave;
  final VoidCallback onSave;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String remainingLabel = remaining < 0
        ? 'Over by ${-remaining}%'
        : remaining == 0
            ? 'Complete'
            : 'Remaining $remaining%';
    final Widget totals = Wrap(
      spacing: 16,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              const TextSpan(
                text: 'Total Weightage: ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              TextSpan(
                text: '$total%',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
        ),
        Text(
          remainingLabel,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );

    final Widget save = FilledButton.icon(
      onPressed: canSave ? onSave : null,
      icon: saving
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(AppIcons.save, size: 16),
      label: Text(saving ? 'Saving…' : 'Save template'),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (compact) ...<Widget>[
            totals,
            if (dirty) ...<Widget>[const SizedBox(height: 8), save],
          ] else
            Row(
              children: <Widget>[
                Expanded(child: totals),
                if (dirty) save,
              ],
            ),
          if (error != null && !complete) ...<Widget>[
            const SizedBox(height: 6),
            Text(error!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ],
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    required this.criterion,
    required this.inherited,
    required this.editable,
    required this.onEdit,
    this.onDelete,
  });

  final EvaluationCriterion criterion;
  final bool inherited;
  final bool editable;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final String percent = EvaluationTemplateHelpers.percentLabel(criterion.weight);
    final String range = '${criterion.minScore}–${criterion.maxScore}';
    final String? description = criterion.description?.trim();
    final bool mobile = ResponsiveHelper.isMobile(context);

    final Widget weight = Text(
      percent,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
    );
    final Widget details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          criterion.title.trim().isEmpty ? criterion.criterionId : criterion.title.trim(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          children: <Widget>[
            Text(
              'Score $range',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            if (description != null && description.isNotEmpty)
              Text(
                description,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
      ],
    );
    final Widget? actions = editable
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: onEdit,
                icon: const Icon(AppIcons.edit, size: 16, color: Color(0xFF475569)),
              ),
              if (!inherited && onDelete != null)
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  icon: const Icon(AppIcons.delete, size: 16, color: Color(0xFFB91C1C)),
                ),
            ],
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                details,
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    weight,
                    const Spacer(),
                    if (actions != null) actions,
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: details),
                const SizedBox(width: 8),
                weight,
                if (actions != null) ...<Widget>[const SizedBox(width: 4), actions],
              ],
            ),
    );
  }
}
