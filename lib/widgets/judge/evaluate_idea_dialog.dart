import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../features/evaluations/models/evaluation_criterion.dart';
import '../../features/evaluations/models/evaluation_template.dart';
import '../../features/evaluations/services/evaluation_templates_service.dart';
import '../../features/evaluations/widgets/criterion_score_card.dart';
import '../../features/ideathons/services/ideathon_settings_service.dart';
import '../../features/org_settings/services/org_settings_service.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../../features/problems/models/problem_model.dart';
import '../../models/score_model.dart';
import '../../features/team/models/team_model.dart';
import '../../features/user/models/user_model.dart';
import '../../shared/feedback/feedback.dart';
import '../../screens/common/app_dialog_template.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';
import '../../utils/firestore_utils.dart';
import '../../features/idea/services/idea_query_service.dart';
import '../../utils/judge_evaluation_feedback_codec.dart';
import '../../utils/judge_evaluation_service.dart';
import '../common/entity_card_pills.dart';
import '../responsive/responsive_dialog_actions.dart';
import '../../workspace/workspace.dart';

/// Template-driven evaluation dialog — shared by judge workspace and ideas
/// list (judge path).
///
/// Renders the org's default [EvaluationTemplate] dynamically. The judge
/// scores each criterion; the **overall** is the auto-computed weighted
/// average displayed live. Per-criterion comments are shown only for
/// criteria with `commentsEnabled: true`. Overall feedback is optional.
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
  late Future<void> _settingsFuture;
  EvaluationTemplate? _template;
  final Map<String, int> _scores = <String, int>{};
  final Map<String, String> _comments = <String, String>{};
  late TextEditingController _overallRemarks;
  bool _saving = false;
  int _attachmentCount = 0;
  ProblemModel? _problem;
  bool _loadingProblem = false;

  @override
  void initState() {
    super.initState();
    _overallRemarks = TextEditingController();
    _problem = widget.problem;
    _settingsFuture = _initialize();
    if (_problem == null && widget.idea.problemId.trim().isNotEmpty) {
      _loadProblem();
    }
  }

  Future<void> _initialize() async {
    await OrgSettingsService.instance.ensureLoaded(orgId: widget.judge.orgId);
    final List<AttachmentModel> attachments = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.idea,
      entityId: widget.idea.ideaId,
    );
    _attachmentCount = attachments.length;
    final EvaluationTemplate template = _resolveTemplateForExistingScore();
    _hydrateForTemplate(template);
  }

  EvaluationTemplate _resolveTemplateForExistingScore() {
    final ScoreModel? existing = widget.latestJudgeScore;
    final String problemDept = widget.idea.problemDepartmentCode.trim().toUpperCase();
    final bool isDepartmentScoped = problemDept.isNotEmpty;
    if (widget.idea.isInIdeathon ||
        widget.idea.status == IdeaStatus.ideathonAssigned ||
        widget.idea.status == IdeaStatus.ideathonEvaluated) {
      final String templateId = IdeathonSettingsService.ideathonEvaluationTemplateId(widget.idea.orgId);
      return EvaluationTemplatesService.resolveTemplate(
        templateId,
        departmentCode: isDepartmentScoped ? problemDept : null,
        includeDepartmentExtensions: isDepartmentScoped,
      );
    }
    if (existing != null && existing.templateId.trim().isNotEmpty) {
      return EvaluationTemplatesService.resolveTemplate(
        existing.templateId,
        departmentCode: isDepartmentScoped ? problemDept : null,
        includeDepartmentExtensions: isDepartmentScoped,
      );
    }
    if (isDepartmentScoped) {
      return EvaluationTemplatesService.defaultTemplateForDepartment(problemDept);
    }
    return EvaluationTemplatesService.defaultTemplate;
  }

  void _hydrateForTemplate(EvaluationTemplate template) {
    final ScoreModel? existing = widget.latestJudgeScore;
    final JudgeEvaluationDecodedFeedback? legacy = existing == null
        ? null
        : JudgeEvaluationFeedbackCodec.tryDecode(existing.feedback);

    _scores.clear();
    _comments.clear();

    for (final EvaluationCriterion c in template.orderedCriteria) {
      int? seed;
      if (existing != null) {
        final double? saved = existing.criteriaScores[c.criterionId];
        if (saved != null) {
          seed = saved.round().clamp(c.minScore, c.maxScore);
        } else if (legacy != null) {
          // Legacy v1 records used three fixed dimensions; reuse them when the
          // template happens to share the same criterion ids.
          switch (c.criterionId) {
            case 'innovation':
              seed = legacy.innovation.clamp(c.minScore, c.maxScore);
              break;
            case 'feasibility':
              seed = legacy.feasibility.clamp(c.minScore, c.maxScore);
              break;
            case 'impact':
              seed = legacy.impact.clamp(c.minScore, c.maxScore);
              break;
          }
        }
      }
      _scores[c.criterionId] = seed ?? ((c.minScore + c.maxScore) ~/ 2);
      if (c.commentsEnabled) {
        final String existingComment = existing?.criteriaComments[c.criterionId] ?? '';
        if (existingComment.isNotEmpty) {
          _comments[c.criterionId] = existingComment;
        }
      }
    }

    final String existingRemarks = existing == null
        ? ''
        : JudgeEvaluationFeedbackCodec.displayRemarks(existing.feedback);
    _overallRemarks.text = existingRemarks;
    if (mounted) setState(() => _template = template);
  }

  Future<void> _loadProblem() async {
    setState(() => _loadingProblem = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreUtils.hkzProblems)
          .doc(widget.idea.problemId)
          .get();
      if (doc.exists && doc.data() != null && mounted) {
        setState(() => _problem = ProblemModel.fromMap(doc.id, doc.data()!));
      }
    } finally {
      if (mounted) setState(() => _loadingProblem = false);
    }
  }

  @override
  void dispose() {
    _overallRemarks.dispose();
    super.dispose();
  }

  Future<void> _openAttachments() async {
    final List<AttachmentModel> list = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.idea,
      entityId: widget.idea.ideaId,
    );
    if (!mounted) return;
    if (list.isEmpty) {
      FeedbackService.showInfo(
        context,
        title: 'No attachments',
        message: 'No attachments for this idea.',
      );
      return;
    }
    if (list.length == 1) {
      WorkspaceNavigator.openAttachment(context, list.first.attachmentId);
      return;
    }
    WorkspaceNavigator.openIdea(context, widget.idea.ideaId);
  }

  String _attachmentPillLabel() {
    if (_attachmentCount <= 0) return 'Attachments';
    return '$_attachmentCount Attachment${_attachmentCount == 1 ? '' : 's'}';
  }

  double _liveOverall() {
    final EvaluationTemplate? t = _template;
    if (t == null) return 0;
    final Map<String, double> doubles = <String, double>{
      for (final MapEntry<String, int> e in _scores.entries) e.key: e.value.toDouble(),
    };
    return t.computeOverall(doubles);
  }

  Future<void> _save() async {
    final EvaluationTemplate? template = _template;
    if (template == null) return;
    if (widget.idea.status == IdeaStatus.draft) {
      FeedbackService.showWarning(
        context,
        title: 'Evaluation blocked',
        message: 'This idea is pending payment verification before it can be evaluated.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final Map<String, double> scores = <String, double>{
        for (final MapEntry<String, int> e in _scores.entries) e.key: e.value.toDouble(),
      };
      final Map<String, String> comments = <String, String>{
        for (final MapEntry<String, String> e in _comments.entries)
          if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
      };
      await JudgeEvaluationService.saveEvaluation(
        judge: widget.judge,
        idea: widget.idea,
        template: template,
        criteriaScores: scores,
        criteriaComments: comments,
        overallFeedback: _overallRemarks.text,
        ideathonId: widget.idea.ideathonId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(
        context,
        title: 'Failed to save evaluation',
        message: '$e',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _weightLabel(EvaluationCriterion criterion, EvaluationTemplate template) {
    double total = 0;
    for (final EvaluationCriterion c in template.criteria) {
      if (c.weight > 0) total += c.weight;
    }
    if (total <= 0) return '—';
    final double pct = (criterion.weight / total) * 100;
    if (pct >= 10) return '${pct.toStringAsFixed(0)}%';
    return '${pct.toStringAsFixed(1)}%';
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final teamName = (widget.team?.teamName ?? '').trim().isNotEmpty
        ? widget.team!.teamName.trim()
        : widget.idea.teamId;
    final problemLine = (_problem?.title ?? widget.idea.problemTitle).trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.idea.ideaTitle.trim().isNotEmpty
              ? widget.idea.ideaTitle.trim()
              : widget.idea.problemNumber,
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
      ],
    );
  }

  Widget _buildOverallStrip(BuildContext context, EvaluationTemplate template) {
    final ThemeData theme = Theme.of(context);
    final double overall = _liveOverall();
    final int scale = template.scoringScale;
    final Color accent = JudgeScoreGridHueLookup.forOverall(overall, scale);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppIcons.insights, color: accent, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  template.templateName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF334155),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Weighted overall (auto-computed)',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Text(
            overall.toStringAsFixed(1),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              '/ $scale',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBody(BuildContext context, EvaluationTemplate template) {
    final ThemeData theme = Theme.of(context);
    final List<EvaluationCriterion> ordered = template.orderedCriteria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildHeader(context),
        const SizedBox(height: 12),
        _buildOverallStrip(context, template),
        const SizedBox(height: 12),
        if ((template.description ?? '').trim().isNotEmpty) ...<Widget>[
          Text(
            template.description!.trim(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Criteria',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF475569),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        for (final EvaluationCriterion c in ordered)
          CriterionScoreCard(
            criterion: c,
            value: _scores[c.criterionId],
            readOnly: widget.readOnly,
            onChanged: (int v) => setState(() => _scores[c.criterionId] = v),
            weightLabel: _weightLabel(c, template),
            ownershipBadge: c.sourceType == EvaluationCriterionSourceType.department
                ? 'Department specific'
                : null,
            comment: _comments[c.criterionId],
            onCommentChanged: c.commentsEnabled
                ? (String s) => _comments[c.criterionId] = s
                : null,
          ),
        const SizedBox(height: 6),
        TextField(
          controller: _overallRemarks,
          enabled: !widget.readOnly,
          maxLines: 3,
          minLines: 2,
          decoration: const InputDecoration(
            labelText: 'Overall feedback (optional)',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: EntityCardPills.workspace(
            _attachmentPillLabel(),
            ContextPillSemantic.generic,
            _openAttachments,
            icon: AppIcons.attachments,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Evaluate submission', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder<void>(
          future: _settingsFuture,
          builder: (BuildContext context, AsyncSnapshot<void> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return _buildLoading();
            }
            final EvaluationTemplate? t = _template;
            if (t == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No evaluation template configured.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                ),
              );
            }
            return _buildBody(context, t);
          },
        ),
        const SizedBox(height: 16),
        ResponsiveDialogActions(
          children: <Widget>[
            if (widget.readOnly)
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Close'))
            else ...<Widget>[
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (_saving || _template == null) ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Submit evaluation'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Internal hue helper that mirrors [JudgeScoreGrid]'s color ramp at any scale.
class JudgeScoreGridHueLookup {
  JudgeScoreGridHueLookup._();

  static Color forOverall(double value, int scale) {
    if (scale <= 1) return const Color(0xFF6366F1);
    final double t = (value / scale).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFDC2626), const Color(0xFF16A34A), t)!;
  }
}
