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

  Future<void> _openEvaluateEvaluated(JudgeEvaluationEvaluatedRow row) async {
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => IdeaDetailScreen(
          ideaId: ideaId,
          currentUser: widget.user,
          onBack: () => Navigator.of(ctx).pop(),
        ),
      ),
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
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Evaluation queue',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                  ),
                ),
                TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabs,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: const Color(0xFF0F172A),
                unselectedLabelColor: const Color(0xFF64748B),
                tabs: const <Tab>[
                  Tab(text: 'Pending review'),
                  Tab(text: 'Evaluated'),
                  Tab(text: 'Feedback'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
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
                    onViewEvaluation: _openEvaluateEvaluated,
                    onEditEvaluation: _openEvaluateEvaluated,
                    onViewDetails: (r) => _openIdeaDetail(r.idea.ideaId),
                  ),
                  EvaluationFeedbackSection(rows: vm.feedback),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
