import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/attachment_model.dart';
import '../../models/idea_model.dart';
import '../../models/problem_model.dart';
import '../../models/score_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/attachment_service.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/idea_query_service.dart';
import '../../utils/judge_evaluation_feedback_codec.dart';
import '../../utils/judge_evaluation_service.dart';
import '../../screens/common/app_dialog_template.dart';
import '../attachment_viewer.dart';
import '../responsive/responsive_dialog_actions.dart';
import 'judge_score_grid.dart';

/// Premium evaluation dialog — shared by judge workspace and ideas list (judge path).
class EvaluateIdeaDialog extends StatefulWidget {
  const EvaluateIdeaDialog({
    super.key,
    required this.judge,
    required this.idea,
    this.team,
    this.problem,
    this.latestJudgeScore,
    this.readOnly = false,
  });

  final UserModel judge;
  final IdeaModel idea;
  final TeamModel? team;
  final ProblemModel? problem;
  final ScoreModel? latestJudgeScore;
  final bool readOnly;

  static Future<bool?> showForIdeaListItem(
    BuildContext context, {
    required UserModel judge,
    required IdeaListItem item,
  }) {
    return showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      width: DialogWidthPreset.wide,
      child: EvaluateIdeaDialog(
        judge: judge,
        idea: item.idea,
        team: item.team,
        problem: null,
        latestJudgeScore: item.score,
      ),
    );
  }

  @override
  State<EvaluateIdeaDialog> createState() => _EvaluateIdeaDialogState();
}

class _EvaluateIdeaDialogState extends State<EvaluateIdeaDialog> {
  late int _overall;
  late int _innovation;
  late int _feasibility;
  late int _impact;
  late String _recommendation;
  late TextEditingController _remarks;
  bool _saving = false;
  ProblemModel? _problem;
  bool _loadingProblem = false;

  static const List<String> _recValues = <String>['none', 'advance', 'revise', 'reject'];

  @override
  void initState() {
    super.initState();
    final existing = widget.latestJudgeScore;
    final raw = existing?.score ?? 5;
    _overall = raw.round().clamp(1, 10);
    final decoded = existing != null ? JudgeEvaluationFeedbackCodec.tryDecode(existing.feedback) : null;
    _innovation = decoded?.innovation ?? 5;
    _feasibility = decoded?.feasibility ?? 5;
    _impact = decoded?.impact ?? 5;
    _recommendation = decoded?.recommendation ?? 'none';
    if (!_recValues.contains(_recommendation)) _recommendation = 'none';
    _remarks = TextEditingController(text: JudgeEvaluationFeedbackCodec.displayRemarks(existing?.feedback ?? ''));
    _problem = widget.problem;
    if (_problem == null && widget.idea.problemId.trim().isNotEmpty) {
      _loadProblem();
    }
  }

  Future<void> _loadProblem() async {
    setState(() => _loadingProblem = true);
    try {
      final doc = await FirebaseFirestore.instance.collection(FirestoreUtils.hkzProblems).doc(widget.idea.problemId).get();
      if (doc.exists && doc.data() != null && mounted) {
        setState(() => _problem = ProblemModel.fromMap(doc.id, doc.data()!));
      }
    } finally {
      if (mounted) setState(() => _loadingProblem = false);
    }
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _previewAttachments() async {
    final list = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.idea,
      entityId: widget.idea.ideaId,
    );
    if (!mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No attachments for this idea.')));
      return;
    }
    await showAppDialog<void>(
      context: context,
      width: DialogWidthPreset.wide,
      child: AttachmentViewerDialog(title: 'Idea attachments', attachments: list, embedded: true),
    );
  }

  Future<void> _save() async {
    if (widget.idea.status == IdeaStatus.pendingSubmission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This idea is pending payment verification before it can be evaluated.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await JudgeEvaluationService.saveEvaluation(
        judge: widget.judge,
        idea: widget.idea,
        overallScore: _overall,
        innovation: _innovation,
        feasibility: _feasibility,
        impact: _impact,
        recommendation: _recommendation,
        remarks: _remarks.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teamName = (widget.team?.teamName ?? '').trim().isNotEmpty ? widget.team!.teamName.trim() : widget.idea.teamId;
    final problemLine = (_problem?.title ?? widget.idea.problemTitle).trim();
    final formBody = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.idea.ideaTitle.trim().isNotEmpty ? widget.idea.ideaTitle.trim() : widget.idea.problemNumber,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                problemLine.isEmpty ? 'Problem' : problemLine,
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
              Row(
                children: <Widget>[
                  const Icon(AppIcons.teams, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(teamName, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B))),
                  ),
                ],
              ),
              if (_loadingProblem) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 16),
              JudgeScoreGrid(
                label: 'Overall',
                selectedValue: _overall,
                onChanged: (v) => setState(() => _overall = v),
                hint: 'Tap 1–10 for holistic score',
              ),
              const SizedBox(height: 18),
              Text('Criteria', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF475569))),
              const SizedBox(height: 8),
              JudgeScoreGrid(label: 'Innovation', compact: true, selectedValue: _innovation, onChanged: (v) => setState(() => _innovation = v)),
              const SizedBox(height: 8),
              JudgeScoreGrid(label: 'Feasibility', compact: true, selectedValue: _feasibility, onChanged: (v) => setState(() => _feasibility = v)),
              const SizedBox(height: 8),
              JudgeScoreGrid(label: 'Impact', compact: true, selectedValue: _impact, onChanged: (v) => setState(() => _impact = v)),
              const SizedBox(height: 16),
              Text('Recommendation', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _recommendation,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'none', child: Text('No recommendation')),
                  DropdownMenuItem(value: 'advance', child: Text('Advance / strong merit')),
                  DropdownMenuItem(value: 'revise', child: Text('Request revisions')),
                  DropdownMenuItem(value: 'reject', child: Text('Not recommended')),
                ],
                onChanged: (v) => setState(() => _recommendation = v ?? 'none'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _remarks,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Remarks & feedback',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _previewAttachments,
                icon: const Icon(AppIcons.attachments, size: 18),
                label: const Text('Preview attachments'),
              ),
            ],
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Evaluate submission', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        formBody,
        const SizedBox(height: 16),
        ResponsiveDialogActions(
          children: <Widget>[
            if (widget.readOnly)
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Close'))
            else ...<Widget>[
              TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Submit evaluation')),
            ],
          ],
        ),
      ],
    );
  }
}
