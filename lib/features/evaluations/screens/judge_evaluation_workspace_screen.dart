import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/rich_tabs.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../ideathons/services/ideathon_service.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/user_model.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../models/evaluation_template.dart';
import '../models/score_model.dart';
import '../services/evaluation_templates_service.dart';
import '../services/judge_evaluation_service.dart';
import '../widgets/evaluate_idea_dialog.dart';
import '../widgets/evaluation_feedback_section.dart';
import '../widgets/evaluation_summary_strip.dart';
import '../widgets/evaluated_idea_list.dart';
import '../widgets/pending_evaluation_list.dart';

/// Judge evaluation workspace (Scoring tab / event-scoped evaluation entry).
///
/// Optional [ideathonId] scopes the same UX to one event — no second screen.
class JudgeEvaluationWorkspaceScreen extends StatefulWidget {
  const JudgeEvaluationWorkspaceScreen({
    super.key,
    required this.user,
    this.ideathonId = '',
    this.ideathonName = '',
  });

  final UserModel user;
  final String ideathonId;
  final String ideathonName;

  @override
  State<JudgeEvaluationWorkspaceScreen> createState() => _JudgeEvaluationWorkspaceScreenState();
}

class _JudgeEvaluationWorkspaceScreenState extends State<JudgeEvaluationWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Future<JudgeEvaluationWorkspaceVm>? _future;

  String get _eventId => widget.ideathonId.trim();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _future = JudgeEvaluationService.loadWorkspace(widget.user, ideathonId: _eventId);
  }

  @override
  void didUpdateWidget(covariant JudgeEvaluationWorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ideathonId != widget.ideathonId || oldWidget.user.userId != widget.user.userId) {
      _reload();
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    JudgeEvaluationService.clearCache();
    setState(() {
      _future = JudgeEvaluationService.loadWorkspace(widget.user, ideathonId: _eventId);
    });
    await _future;
  }

  Future<void> _openEvaluate(JudgeEvaluationPendingRow row) {
    return _openEvaluationDialog(
      idea: row.idea,
      teamName: row.teamName,
      ideathonId: row.ideathonId,
      evaluationTemplateId: row.evaluationTemplateId,
      ideathonName: row.ideathonName,
      ideathonSchedule: row.ideathonSchedule,
    );
  }

  Future<void> _openViewEvaluation(JudgeEvaluationEvaluatedRow row) {
    return _openEvaluationDialog(
      idea: row.idea,
      teamName: row.teamName,
      ideathonId: row.ideathonId,
      evaluationTemplateId: row.evaluationTemplateId,
      ideathonName: row.ideathonName,
      ideathonSchedule: row.ideathonSchedule,
      latestScore: row.latestScore,
      readOnly: true,
    );
  }

  Future<void> _openViewFeedback(JudgeEvaluationFeedbackRow row) {
    return _openEvaluationDialog(
      idea: row.idea,
      teamName: row.teamName,
      ideathonId: row.ideathonId,
      evaluationTemplateId: row.evaluationTemplateId,
      ideathonName: row.ideathonName,
      ideathonSchedule: row.ideathonSchedule,
      latestScore: row.latestScore,
      readOnly: true,
    );
  }

  Future<void> _openEvaluationDialog({
    required IdeaModel idea,
    required String teamName,
    required String ideathonId,
    required String evaluationTemplateId,
    required String ideathonName,
    required String ideathonSchedule,
    ScoreModel? latestScore,
    bool readOnly = false,
  }) async {
    EvaluationTemplate? overrideTemplate;
    final String eventId = ideathonId.trim();
    if (eventId.isNotEmpty) {
      await OrgSettingsService.instance.ensureLoaded(orgId: widget.user.orgId);
      final event = await IdeathonService.fetchById(eventId);
      if (event != null) {
        overrideTemplate = EvaluationTemplatesService.resolveForEvent(
          templateId: event.evaluationTemplateId.isNotEmpty
              ? event.evaluationTemplateId
              : evaluationTemplateId,
          departmentCode: event.departmentId,
          eventCriteria: event.evaluationCriteria,
        );
      }
    }
    if (!mounted) return;
    final bool? ok = await showAppDialog<bool>(
      context: context,
      barrierDismissible: readOnly,
      width: DialogWidthPreset.wide,
      child: EvaluateIdeaDialog(
        judge: widget.user,
        idea: idea,
        team: null,
        teamLabel: teamName,
        problem: null,
        latestJudgeScore: latestScore,
        readOnly: readOnly,
        ideathonId: ideathonId,
        forcedTemplateId: evaluationTemplateId,
        overrideTemplate: overrideTemplate,
        ideathonName: ideathonName,
        ideathonSchedule: ideathonSchedule,
      ),
    );
    if (ok == true && mounted) await _reload();
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
              pendingCountByEvent: vm.pendingCountByEvent,
              evaluatedCountByEvent: vm.evaluatedCountByEvent,
              onEvaluate: _openEvaluate,
              onViewDetails: (JudgeEvaluationPendingRow row) =>
                  WorkspaceNavigator.openIdea(context, row.idea.ideaId),
              onOpenProblem: (JudgeEvaluationPendingRow row) =>
                  WorkspaceNavigator.openProblem(context, row.idea.problemId),
              onOpenTeam: (JudgeEvaluationPendingRow row) =>
                  WorkspaceNavigator.openTeam(context, row.idea.teamId),
            ),
            EvaluatedIdeaList(
              rows: vm.evaluated,
              pendingCountByEvent: vm.pendingCountByEvent,
              evaluatedCountByEvent: vm.evaluatedCountByEvent,
              onViewEvaluation: _openViewEvaluation,
              onViewDetails: (JudgeEvaluationEvaluatedRow row) =>
                  WorkspaceNavigator.openIdea(context, row.idea.ideaId),
              onOpenProblem: (JudgeEvaluationEvaluatedRow row) =>
                  WorkspaceNavigator.openProblem(context, row.idea.problemId),
              onOpenTeam: (JudgeEvaluationEvaluatedRow row) =>
                  WorkspaceNavigator.openTeam(context, row.idea.teamId),
            ),
            EvaluationFeedbackSection(
              rows: vm.feedback,
              pendingCountByEvent: vm.pendingCountByEvent,
              evaluatedCountByEvent: vm.evaluatedCountByEvent,
              onViewEvaluation: _openViewFeedback,
            ),
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
        final bool compact = ResponsiveHelper.isMobile(context);
        final double sectionGap = compact ? 8 : 12;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            EvaluationSummaryStrip(
              pendingCount: vm.pendingCount,
              evaluatedCount: vm.evaluatedCount,
              averageScore: vm.averageScore,
              completionPercent: vm.completionPercent,
            ),
            SizedBox(height: sectionGap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: RichTabBar.horizontalInset(context)),
              child: RichTabBar(
                controller: _tabs,
                tabs: const <RichTabItem>[
                  RichTabItem('Pending', icon: AppIcons.clock),
                  RichTabItem('Evaluated', icon: AppIcons.scoring),
                  RichTabItem('Feedback', icon: AppIcons.feedback),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
            Expanded(child: _buildTabLists(vm)),
          ],
        );
      },
    );
  }
}
