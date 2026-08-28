import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/common/rich_tabs.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../ideathons/services/ideathon_service.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/user_model.dart';
import '../models/evaluation_template.dart';
import '../services/evaluation_templates_service.dart';
import '../services/judge_evaluation_service.dart';
import '../widgets/evaluate_idea_dialog.dart';
import '../widgets/evaluation_feedback_section.dart';
import '../widgets/evaluation_summary_strip.dart';
import '../widgets/evaluated_idea_list.dart';
import '../widgets/pending_evaluation_list.dart';

/// Judge evaluation workspace (Scoring tab / Ideathon Evaluation entry).
///
/// Optional [ideathonId] scopes the same UX to one Ideathon event — no second screen.
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

  Future<void> _openEvaluate(JudgeEvaluationPendingRow row) async {
    EvaluationTemplate? overrideTemplate;
    final String eventId = row.ideathonId.trim();
    if (eventId.isNotEmpty) {
      await OrgSettingsService.instance.ensureLoaded(orgId: widget.user.orgId);
      final event = await IdeathonService.fetchById(eventId);
      if (event != null) {
        overrideTemplate = EvaluationTemplatesService.resolveForEvent(
          templateId: event.evaluationTemplateId.isNotEmpty
              ? event.evaluationTemplateId
              : row.evaluationTemplateId,
          departmentCode: event.departmentId,
          eventCriteria: event.evaluationCriteria,
        );
      }
    }
    if (!mounted) return;
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
        ideathonId: row.ideathonId,
        forcedTemplateId: row.evaluationTemplateId,
        overrideTemplate: overrideTemplate,
        ideathonName: row.ideathonName,
        ideathonSchedule: row.ideathonSchedule,
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
              groupByEvent: !vm.isIdeathonScoped,
              onEvaluate: _openEvaluate,
              onViewDetails: (JudgeEvaluationPendingRow row) =>
                  WorkspaceNavigator.openIdea(context, row.idea.ideaId),
              onOpenProblem: (JudgeEvaluationPendingRow row) =>
                  WorkspaceNavigator.openProblem(context, row.idea.problemId),
            ),
            EvaluatedIdeaList(
              rows: vm.evaluated,
              groupByEvent: !vm.isIdeathonScoped,
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

  Widget _ideathonBanner(JudgeEvaluationWorkspaceVm vm) {
    final String name = (widget.ideathonName.trim().isNotEmpty
            ? widget.ideathonName
            : vm.ideathonName)
        .trim();
    final String templateId = vm.evaluationTemplateId.trim();
    if (name.isEmpty && !vm.isIdeathonScoped) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isMobile(context) ? 12 : 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.ideathons, size: 18, color: Color(0xFF6A38FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isEmpty ? 'Ideathon evaluation' : name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          if (vm.ideathonSchedule.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                const Icon(AppIcons.event, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vm.ideathonSchedule.trim(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          const Text(
            'Only ideas explicitly assigned to you for this Ideathon are listed. Scoring uses this event’s evaluation template.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          if (templateId.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            EntityCardPills.workspace(
              EvaluationTemplatesService.resolveTemplate(templateId).templateName,
              ContextPillSemantic.evaluationTemplate,
              () => WorkspaceNavigator.openEvaluationTemplate(context, templateId),
              icon: AppIcons.scoring,
            ),
          ],
        ],
      ),
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
            if (vm.isIdeathonScoped || widget.ideathonId.trim().isNotEmpty) ...<Widget>[
              _ideathonBanner(vm),
              SizedBox(height: sectionGap),
            ],
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
                  RichTabItem('Pending review'),
                  RichTabItem('Evaluated'),
                  RichTabItem('Feedback'),
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
