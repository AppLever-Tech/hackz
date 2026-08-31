import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../evaluations/assignments/models/evaluation_assignment_conflict.dart';
import '../../evaluations/assignments/services/evaluation_assignment_service.dart';
import '../../evaluations/widgets/evaluator_assignment_row.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_judge_assignment_service.dart';

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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_selected);
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
    final double height = MediaQuery.sizeOf(context).height * 0.78;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Assign judges',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: _saving || _selected.difference(widget.initiallySelected).isEmpty
                        ? null
                        : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Idea: ${widget.row.snapshot.ideaTitle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TextField(
                onChanged: (String v) => setState(() => _search = v),
                style: HackzInputDecoration.fieldTextStyle,
                decoration: HackzInputDecoration.decorate(
                  hintText: 'Search judges…',
                  prefixIcon: const Icon(AppIcons.search, size: 18, color: HackzInputDecoration.iconColor),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          ],
        ),
      ),
    );
  }
}
