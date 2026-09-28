import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_dialog_actions.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../models/evaluation_criterion.dart';

class EvaluationCriterionEditorResult {
  const EvaluationCriterionEditorResult({
    required this.title,
    required this.description,
    required this.weightPercent,
    required this.minScore,
    required this.maxScore,
  });

  final String title;
  final String description;
  final int weightPercent;
  final int minScore;
  final int maxScore;
}

Future<EvaluationCriterionEditorResult?> showEvaluationCriterionEditor({
  required BuildContext context,
  required String title,
  EvaluationCriterion? existing,
  required int currentTotalPercent,
  required int maxWeightPercent,
  int scoringScale = 10,
  bool inherited = false,
}) {
  return showAppDialog<EvaluationCriterionEditorResult>(
    context: context,
    width: DialogWidthPreset.standard,
    child: _EvaluationCriterionEditorDialog(
      dialogTitle: title,
      existing: existing,
      currentTotalPercent: currentTotalPercent,
      maxWeightPercent: maxWeightPercent,
      scoringScale: scoringScale,
      inherited: inherited,
    ),
  );
}

class _EvaluationCriterionEditorDialog extends StatefulWidget {
  const _EvaluationCriterionEditorDialog({
    required this.dialogTitle,
    required this.existing,
    required this.currentTotalPercent,
    required this.maxWeightPercent,
    required this.scoringScale,
    required this.inherited,
  });

  final String dialogTitle;
  final EvaluationCriterion? existing;
  final int currentTotalPercent;
  final int maxWeightPercent;
  final int scoringScale;
  final bool inherited;

  @override
  State<_EvaluationCriterionEditorDialog> createState() =>
      _EvaluationCriterionEditorDialogState();
}

class _EvaluationCriterionEditorDialogState extends State<_EvaluationCriterionEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late int _weight;
  late int _minScore;
  late int _maxScore;
  String? _nameError;

  int get _existingPercent {
    final EvaluationCriterion? c = widget.existing;
    if (c == null) return 0;
    return (c.weight * 100).round().clamp(0, 100);
  }

  int get _othersTotal => widget.currentTotalPercent - _existingPercent;

  int get _nextTotal => _othersTotal + _weight;

  bool get _overWeight => _nextTotal > 100;

  int get _maxWeight => widget.maxWeightPercent < 1 ? 0 : widget.maxWeightPercent;

  @override
  void initState() {
    super.initState();
    final EvaluationCriterion? existing = widget.existing;
    _name = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    final int seedWeight = existing == null
        ? (_maxWeight < 1 ? 0 : _maxWeight.clamp(1, _maxWeight))
        : _existingPercent.clamp(1, _maxWeight < 1 ? 1 : _maxWeight);
    _weight = seedWeight;
    _minScore = existing?.minScore ?? 1;
    _maxScore = existing?.maxScore ?? widget.scoringScale.clamp(2, 100);
    if (_minScore >= _maxScore) {
      _minScore = 1;
      _maxScore = widget.scoringScale.clamp(2, 100);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final String title = _name.text.trim();
    if (title.isEmpty) {
      setState(() => _nameError = 'Criterion name is required.');
      return;
    }
    if (_maxWeight < 1) return;
    if (_overWeight || _weight < 1 || _weight > _maxWeight) return;
    if (_minScore >= _maxScore) return;
    Navigator.of(context).pop(
      EvaluationCriterionEditorResult(
        title: title,
        description: _description.text.trim(),
        weightPercent: _weight,
        minScore: _minScore,
        maxScore: _maxScore,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);
    final bool canSave = _maxWeight >= 1 && !_overWeight && _weight >= 1 && _minScore < _maxScore;
    final Color impactColor = _overWeight
        ? const Color(0xFFB91C1C)
        : _nextTotal == 100
            ? const Color(0xFF047857)
            : const Color(0xFFB45309);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.dialogTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
            if (widget.inherited)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Text(
                  'Inherited',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF4338CA)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.inherited
              ? 'Adjust this inherited criterion for this event only. The organisation template is unchanged.'
              : 'Adds an event-specific criterion. Weightage cannot push the template above 100%.',
          style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),
        HackzInputDecoration.labeledField(
          label: 'Criterion name',
          required: true,
          field: TextField(
            controller: _name,
            style: HackzInputDecoration.compactFieldTextStyle,
            textCapitalization: TextCapitalization.words,
            decoration: HackzInputDecoration.decorate(
              hintText: 'e.g. Market Potential',
              compact: true,
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
        ),
        const SizedBox(height: 12),
        HackzInputDecoration.labeledField(
          label: 'Description',
          field: TextField(
            controller: _description,
            style: HackzInputDecoration.compactFieldTextStyle,
            minLines: 2,
            maxLines: 3,
            decoration: HackzInputDecoration.decorate(
              hintText: 'What should judges assess?',
              compact: true,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _ImpactBanner(
          othersTotal: _othersTotal,
          weight: _weight,
          nextTotal: _nextTotal,
          color: impactColor,
        ),
        const SizedBox(height: 12),
        if (_maxWeight < 1)
          const Text(
            'No remaining weightage. Reduce another criterion first.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
          )
        else
          _LabeledPicker(
            label: 'Weightage (%)',
            child: _ScrollableIntPicker(
              value: _weight.clamp(1, _maxWeight),
              min: 1,
              max: _maxWeight,
              suffix: '%',
              onChanged: (int v) => setState(() => _weight = v),
            ),
          ),
        const SizedBox(height: 12),
        Builder(
          builder: (BuildContext context) {
            final Widget minPicker = _LabeledPicker(
              label: 'Minimum score',
              child: _ScrollableIntPicker(
                value: _minScore.clamp(0, 99),
                min: 0,
                max: (_maxScore - 1).clamp(0, 99),
                onChanged: (int v) => setState(() {
                  _minScore = v;
                  if (_minScore >= _maxScore) _maxScore = _minScore + 1;
                }),
              ),
            );
            final Widget maxPicker = _LabeledPicker(
              label: 'Maximum score',
              child: _ScrollableIntPicker(
                value: _maxScore.clamp(_minScore + 1, 100),
                min: (_minScore + 1).clamp(1, 100),
                max: 100,
                onChanged: (int v) => setState(() {
                  _maxScore = v;
                  if (_minScore >= _maxScore) _minScore = _maxScore - 1;
                }),
              ),
            );
            if (mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[minPicker, const SizedBox(height: 12), maxPicker],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: minPicker),
                const SizedBox(width: 12),
                Expanded(child: maxPicker),
              ],
            );
          },
        ),
        if (_minScore >= _maxScore) ...<Widget>[
          const SizedBox(height: 8),
          const Text(
            'Minimum score must be less than maximum score.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
          ),
        ],
        const SizedBox(height: 16),
        ResponsiveDialogActions(
          children: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: canSave ? _submit : null,
              icon: Icon(widget.existing == null ? AppIcons.add : AppIcons.save, size: 16),
              label: Text(widget.existing == null ? 'Add criterion' : 'Save criterion'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImpactBanner extends StatelessWidget {
  const _ImpactBanner({
    required this.othersTotal,
    required this.weight,
    required this.nextTotal,
    required this.color,
  });

  final int othersTotal;
  final int weight;
  final int nextTotal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String detail = nextTotal > 100
        ? 'Over by ${nextTotal - 100}%. Reduce weightage to ${100 - othersTotal}% or less.'
        : nextTotal == 100
            ? 'Template will total 100%.'
            : 'Remaining ${100 - nextTotal}% after this change.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Total $othersTotal%  +  $weight%  →  $nextTotal%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _LabeledPicker extends StatelessWidget {
  const _LabeledPicker({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ScrollableIntPicker extends StatefulWidget {
  const _ScrollableIntPicker({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
  });

  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  State<_ScrollableIntPicker> createState() => _ScrollableIntPickerState();
}

class _ScrollableIntPickerState extends State<_ScrollableIntPicker> {
  final ScrollController _scroll = ScrollController();
  static const double _itemExtent = 40;

  int get _lo => widget.min <= widget.max ? widget.min : widget.max;
  int get _hi => widget.min <= widget.max ? widget.max : widget.min;
  int get _clamped => widget.value.clamp(_lo, _hi);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
  }

  @override
  void didUpdateWidget(covariant _ScrollableIntPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.min != widget.min || oldWidget.max != widget.max) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jumpToSelected() {
    if (!_scroll.hasClients) return;
    final double offset = ((_clamped - _lo) * _itemExtent) - 48;
    _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Decrease',
            onPressed: _clamped <= _lo ? null : () => widget.onChanged(_clamped - 1),
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              itemExtent: _itemExtent,
              itemCount: _hi - _lo + 1,
              itemBuilder: (BuildContext context, int index) {
                final int n = _lo + index;
                final bool selected = n == _clamped;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => widget.onChanged(n),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF4F46E5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$n${widget.suffix}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Increase',
            onPressed: _clamped >= _hi ? null : () => widget.onChanged(_clamped + 1),
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
