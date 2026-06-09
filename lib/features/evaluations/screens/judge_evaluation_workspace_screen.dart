import 'package:flutter/material.dart';

import '../../user/models/user_model.dart';
import '../services/judge_evaluation_service.dart';
import '../widgets/evaluate_idea_dialog.dart';
import '../widgets/evaluation_feedback_section.dart';
import '../widgets/evaluation_summary_strip.dart';
import '../widgets/evaluated_idea_list.dart';
import '../../../widgets/common/rich_tabs.dart';
import '../widgets/pending_evaluation_list.dart';
import '../../../widgets/loading/hkz_progress_indicator.dart';
import '../../../screens/common/app_dialog_template.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

/// Judge-only evaluation workspace (Scoring tab). Not an idea dashboard clone.
class JudgeEvaluationWorkspaceScreen extends StatefulWidget {
  const JudgeEvaluationWorkspaceScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<JudgeEvaluationWorkspaceScreen> createState() => _JudgeEvaluationWorkspaceScreenState();
}

class _JudgeEvaluationWorkspaceScreenState extends State<JudgeEvaluationWorkspaceScreen>
    with SingleTickerProviderStateMixin {
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
    final ok = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      width: DialogWidthPreset.wide,
      child: EvaluateIdeaDialog(
        judge: widget.user,
        idea: row.idea,
        team: null,
        problem: null,
        latestJudgeScore: null,
      ),
    );
    if (ok == true && mounted) await _reload();
  }

  void _openViewEvaluation(JudgeEvaluationEvaluatedRow row) {
    WorkspaceNavigator.openEvaluation(context, row.latestScore.scoreId);
  }

  Widget _buildTabLists(JudgeEvaluationWorkspaceVm vm) {
    return AnimatedBuilder(
      animation: _tabs,
      builder: (BuildContext context, Widget? child) {
        return IndexedStack(
          index: _tabs.index,
          children: <Widget>[
            PendingEvaluationList(
              rows: vm.pending,
              onEvaluate: _openEvaluate,
              onViewDetails: (JudgeEvaluationPendingRow row) =>
                  WorkspaceNavigator.openIdea(context, row.idea.ideaId),
              onOpenProblem: (JudgeEvaluationPendingRow row) =>
                  WorkspaceNavigator.openProblem(context, row.idea.problemId),
            ),
            EvaluatedIdeaList(
              rows: vm.evaluated,
              onViewEvaluation: _openViewEvaluation,
              onViewDetails: (JudgeEvaluationEvaluatedRow row) =>
                  WorkspaceNavigator.openIdea(context, row.idea.ideaId),
              onOpenProblem: (JudgeEvaluationEvaluatedRow row) =>
                  WorkspaceNavigator.openProblem(context, row.idea.problemId),
            ),
            EvaluationFeedbackSection(rows: vm.feedback),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JudgeEvaluationWorkspaceVm>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: HkzProgressIndicator(size: 36));
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
            Expanded(child: _buildTabLists(vm)),
          ],
        );
      },
    );
  }
}
