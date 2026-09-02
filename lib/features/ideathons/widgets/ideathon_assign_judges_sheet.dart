import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/ui/loading/loading.dart';
import '../../../core/responsive/responsive_dialog_actions.dart';
import '../../evaluations/assignments/models/evaluation_assignment_conflict.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/widgets/evaluator_assignment_row.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_judge_assignment_service.dart';

Future<bool?> showIdeathonAssignJudgesDialog({
  required BuildContext context,
  required IdeathonJudgeAssignmentRow row,
  required List<UserModel> evaluators,
  required Set<String> initiallySelected,
  required Future<void> Function(Set<String> judgeIds) onSave,
}) {
  return showAppDialog<bool>(
    context: context,
    width: DialogWidthPreset.standard,
    child: IdeathonAssignJudgesSheet(
      row: row,
      evaluators: evaluators,
      initiallySelected: initiallySelected,
      onSave: onSave,
    ),
  );
}

class IdeathonAssignJudgesSheet extends StatefulWidget {
  const IdeathonAssignJudgesSheet({
    super.key,
    required this.row,
    required this.evaluators,
    required this.initiallySelected,
    required this.onSave,
  });

  final IdeathonJudgeAssignmentRow row;
  final List<UserModel> evaluators;
  final Set<String> initiallySelected;
  final Future<void> Function(Set<String> judgeIds) onSave;

  @override
  State<IdeathonAssignJudgesSheet> createState() => _IdeathonAssignJudgesSheetState();
}

class _IdeathonAssignJudgesSheetState extends State<IdeathonAssignJudgesSheet> {
  late Set<String> _selected;
  bool _saving = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initiallySelected);
  }

  List<UserModel> get _filtered {
    final String q = _search.trim().toLowerCase();
    return widget.evaluators.where((UserModel u) {
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) || u.userId.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String get _ideaTitle {
    final String title = widget.row.snapshot.ideaTitle.trim();
    return title.isEmpty ? widget.row.ideaId : title;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Saving assignments',
        message: 'Assigning judges to this idea…',
        successMessage: 'Assignments saved for this ideathon idea',
        successHold: const Duration(milliseconds: 1400),
        task: () => widget.onSave(_selected),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to assign', message: '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double listHeight = (MediaQuery.sizeOf(context).height * 0.42).clamp(220.0, 420.0);
    final String ideaTitle = _ideaTitle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Assign Judges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        Text(
          ideaTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (String v) => setState(() => _search = v),
          style: HackzInputDecoration.compactFieldTextStyle,
          decoration: HackzInputDecoration.decorate(
            compact: true,
            hintText: 'Search judges…',
            prefixIcon: const Icon(AppIcons.search, size: 18, color: HackzInputDecoration.iconColor),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: listHeight,
          child: _filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No judges match your search.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                )
              : ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (BuildContext context, int index) {
                    final UserModel judge = _filtered[index];
                    final EvaluationAssignmentConflict conflict =
                        EvaluationAssignmentService.validateConflict(
                      judge: judge,
                      idea: widget.row.idea,
                      team: widget.row.team,
                    );
                    final bool already = widget.initiallySelected.contains(judge.userId);
                    final bool selected = _selected.contains(judge.userId);
                    return EvaluatorAssignmentRow(
                      evaluator: judge,
                      selected: selected,
                      workloadLabel: already ? 'Assigned' : '',
                      conflictLabel: conflict.isConflict ? conflict.reasons.join(' · ') : null,
                      enabled: !already && !conflict.isConflict,
                      onToggle: () {
                        if (already || conflict.isConflict) return;
                        setState(() {
                          if (selected) {
                            _selected.remove(judge.userId);
                          } else {
                            _selected.add(judge.userId);
                          }
                        });
                      },
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        ResponsiveDialogActions(
          children: <Widget>[
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving || _selected.difference(widget.initiallySelected).isEmpty ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6A38FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
