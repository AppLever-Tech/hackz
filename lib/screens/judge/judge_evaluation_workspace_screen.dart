import 'package:flutter/material.dart';

import '../../models/attachment_model.dart';
import '../../models/user_model.dart';
import '../../utils/attachment_service.dart';
import '../../utils/judge_evaluation_service.dart';
import '../../widgets/attachment_viewer.dart';
import '../../widgets/judge/evaluate_idea_dialog.dart';
import '../../widgets/judge/evaluation_feedback_section.dart';
import '../../widgets/judge/evaluation_summary_strip.dart';
import '../../widgets/judge/evaluated_idea_list.dart';
import '../../widgets/common/rich_tabs.dart';
import '../../widgets/judge/pending_evaluation_list.dart';
import '../common/idea_detail_screen.dart';

/// Judge-only evaluation workspace (Scoring tab). Not an idea dashboard clone.
class JudgeEvaluationWorkspaceScreen extends StatefulWidget {
  const JudgeEvaluationWorkspaceScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<JudgeEvaluationWorkspaceScreen> createState() => _JudgeEvaluationWorkspaceScreenState();
}

class _JudgeEvaluationWorkspaceScreenState extends State<JudgeEvaluationWorkspaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Future<JudgeEvaluationWorkspaceVm>? _future;
  String? _selectedIdeaId;

  static const double _splitBreakpoint = 900;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _future = JudgeEvaluationService.loadWorkspace(widget.user);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    JudgeEvaluationService.clearCache();
    setState(() {
      _future = JudgeEvaluationService.loadWorkspace(widget.user);
    });
    await _future;
  }

  Future<void> _openEvaluate(JudgeEvaluationPendingRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EvaluateIdeaDialog(
        judge: widget.user,
        idea: row.idea,
        team: null,
        problem: null,
        latestJudgeScore: null,
      ),
    );
    if (ok == true && mounted) await _reload();
  }

  Future<void> _openViewEvaluation(JudgeEvaluationEvaluatedRow row) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EvaluateIdeaDialog(
        judge: widget.user,
        idea: row.idea,
        team: null,
        problem: null,
        latestJudgeScore: row.latestScore,
        readOnly: true,
      ),
    );
  }

  Future<void> _openEditEvaluation(JudgeEvaluationEvaluatedRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EvaluateIdeaDialog(
        judge: widget.user,
        idea: row.idea,
        team: null,
        problem: null,
        latestJudgeScore: row.latestScore,
      ),
    );
    if (ok == true && mounted) await _reload();
  }

  Future<void> _openAttachments(JudgeEvaluationPendingRow row) async {
    final list = await AttachmentService.fetchActiveAttachments(
      entityType: AttachmentEntityType.idea,
      entityId: row.idea.ideaId,
    );
    if (!mounted) return;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No attachments for this idea.')));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AttachmentViewerDialog(title: 'Idea attachments', attachments: list),
    );
  }

  void _openIdeaDetail(String ideaId) {
    setState(() => _selectedIdeaId = ideaId);
  }

  void _closeIdeaDetail() {
    setState(() => _selectedIdeaId = null);
  }

  Widget _buildDetailBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: _closeIdeaDetail,
        icon: const Icon(Icons.arrow_back),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        visualDensity: VisualDensity.compact,
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildIdeaDetailPane() {
    final ideaId = _selectedIdeaId;
    if (ideaId == null) return const SizedBox.shrink();
    return Column(
      key: ValueKey<String>(ideaId),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildDetailBackButton(),
        Expanded(
          child: IdeaDetailScreen(
            ideaId: ideaId,
            currentUser: widget.user,
            embedded: true,
            onBack: _closeIdeaDetail,
          ),
        ),
      ],
    );
  }

  Widget _buildTabLists(JudgeEvaluationWorkspaceVm vm) {
    return TabBarView(
      controller: _tabs,
      children: <Widget>[
        PendingEvaluationList(
          rows: vm.pending,
          onEvaluate: _openEvaluate,
          onViewDetails: (r) => _openIdeaDetail(r.idea.ideaId),
          onOpenAttachments: _openAttachments,
        ),
        EvaluatedIdeaList(
          rows: vm.evaluated,
          onViewEvaluation: _openViewEvaluation,
          onEditEvaluation: _openEditEvaluation,
          onViewDetails: (r) => _openIdeaDetail(r.idea.ideaId),
        ),
        EvaluationFeedbackSection(rows: vm.feedback),
      ],
    );
  }

  Widget _buildWorkspaceBody(JudgeEvaluationWorkspaceVm vm, BoxConstraints constraints) {
    final showSplit = _selectedIdeaId != null && constraints.maxWidth >= _splitBreakpoint;

    if (_selectedIdeaId != null && !showSplit) {
      return _buildIdeaDetailPane();
    }

    final lists = _buildTabLists(vm);

    if (!showSplit) {
      return lists;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: lists),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        Expanded(child: _buildIdeaDetailPane()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JudgeEvaluationWorkspaceVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Unable to load workspace: ${snapshot.error}'));
        }
        final vm = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            EvaluationSummaryStrip(
              pendingCount: vm.pendingCount,
              evaluatedCount: vm.evaluatedCount,
              averageScore: vm.averageScore,
              completionPercent: vm.completionPercent,
            ),
            const SizedBox(height: 12),
            RichTabBar(
              controller: _tabs,
              tabs: const <RichTabItem>[
                RichTabItem('Pending review'),
                RichTabItem('Evaluated'),
                RichTabItem('Feedback'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => _buildWorkspaceBody(vm, constraints),
              ),
            ),
          ],
        );
      },
    );
  }
}
