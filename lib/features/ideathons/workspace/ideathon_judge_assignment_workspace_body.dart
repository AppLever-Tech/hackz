import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../events/models/event_kind.dart';
import '../../events/widgets/event_labeled_field.dart';
import '../../events/widgets/workspace_collapsible_section.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_judge_assignment_service.dart';
import '../widgets/ideathon_assign_judges_sheet.dart';
import '../widgets/ideathon_event_workspace_header.dart';
import 'ideathon_judge_assignment_workspace_loader.dart';

class IdeathonJudgeAssignmentWorkspaceBody extends StatefulWidget {
  const IdeathonJudgeAssignmentWorkspaceBody({
    super.key,
    required this.vm,
    this.actor,
  });

  final IdeathonJudgeAssignmentWorkspaceViewModel vm;
  final UserModel? actor;

  @override
  State<IdeathonJudgeAssignmentWorkspaceBody> createState() =>
      _IdeathonJudgeAssignmentWorkspaceBodyState();
}

class _IdeathonJudgeAssignmentWorkspaceBodyState
    extends State<IdeathonJudgeAssignmentWorkspaceBody> {
  late IdeathonJudgeAssignmentWorkspaceViewModel _vm;
  bool _busy = false;

  static const EventKind _kind = EventKind.ideathon;
  static const double _metricLabelWidth = 140;
  static const TextStyle _metricValueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.3,
    height: 1.1,
    color: Color(0xFF0F172A),
  );

  IdeathonJudgeAssignmentViewModel get _assignments => _vm.assignments;

  @override
  void initState() {
    super.initState();
    _vm = widget.vm;
  }

  @override
  void didUpdateWidget(covariant IdeathonJudgeAssignmentWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm != widget.vm) _vm = widget.vm;
  }

  bool get _canManage =>
      IdeathonJudgeAssignmentService.canManageAssignments(widget.actor) &&
      !_assignments.evaluationLocked;

  Future<void> _reload() async {
    final IdeathonJudgeAssignmentWorkspaceViewModel next =
        await IdeathonJudgeAssignmentWorkspaceLoader.load(_assignments.ideathon.ideathonId);
    if (!mounted) return;
    setState(() => _vm = next);
  }

  Future<void> _openAssignSheet(IdeathonJudgeAssignmentRow row) async {
    if (_assignments.evaluationLocked) {
      FeedbackService.showWarning(
        context,
        title: 'Assignments locked',
        message: 'Judge assignments cannot be changed after evaluation has started.',
      );
      return;
    }
    if (!_canManage) {
      FeedbackService.showError(
        context,
        title: 'Permission denied',
        message: 'Only Department Admin can assign Ideathon judges.',
      );
      return;
    }

    final Set<String> selected = row.assignedJudgeIds.toSet();
    final bool? saved = await showIdeathonAssignJudgesDialog(
      context: context,
      row: row,
      evaluators: _assignments.evaluators,
      initiallySelected: selected,
      onSave: (Set<String> judgeIds) async {
        final Set<String> toAdd = judgeIds.difference(selected);
        if (toAdd.isEmpty) return;
        await IdeathonJudgeAssignmentService.assignJudgesToIdea(
          actor: widget.actor!,
          ideathonId: _assignments.ideathon.ideathonId,
          ideaId: row.ideaId,
          judgeIds: toAdd,
        );
      },
    );
    if (saved == true && mounted) await _reload();
  }

  Future<void> _remove(EvaluationAssignmentModel assignment) async {
    if (!_canManage) return;
    setState(() => _busy = true);
    try {
      await IdeathonJudgeAssignmentService.removeAssignment(
        actor: widget.actor!,
        ideathonId: _assignments.ideathon.ideathonId,
        assignmentId: assignment.assignmentId,
      );
      await _reload();
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Judge removed',
        message: 'Assignment updated for this Ideathon.',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to remove', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final IdeathonJudgeAssignmentMetrics metrics = _assignments.metrics;
    final String entries = _kind.entriesLabel.toLowerCase();

    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        ideathonEventWorkspaceHeader(
          event: _assignments.ideathon,
          organisationName: _vm.organisationName,
        ),
        const SizedBox(height: 14),
        if (_assignments.evaluationLocked) ...<Widget>[
          _lockedBanner(),
          const SizedBox(height: 12),
        ],
        if (_assignments.workloads.isNotEmpty) ...<Widget>[
          WorkspaceCollapsibleSection(
            title: 'Judge workload',
            icon: AppIcons.judges,
            collapsible: false,
            initiallyExpanded: true,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _assignments.workloads
                  .map(
                    (IdeathonJudgeWorkload w) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: w.ideaCount == 0 ? const Color(0xFFFFF7ED) : const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: w.ideaCount == 0 ? const Color(0xFFFED7AA) : const Color(0xFFDDD6FE),
                        ),
                      ),
                      child: Text(
                        '${w.displayName} · ${w.ideaCount} ${w.ideaCount == 1 ? _kind.payableItemLabel.toLowerCase() : entries}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: w.ideaCount == 0 ? const Color(0xFFC2410C) : const Color(0xFF5B21B6),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 10),
        ],
        WorkspaceCollapsibleSection(
          title: 'Assignments',
          icon: AppIcons.judges,
          collapsible: false,
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _metric(
                icon: _kind.entriesIcon,
                label: 'Registered $entries',
                value: '${metrics.totalIdeas}',
              ),
              _metric(
                icon: AppIcons.workflowApproved,
                label: 'Assigned',
                value: '${metrics.assignedIdeas}',
              ),
              _metric(
                icon: AppIcons.info,
                label: 'Unassigned',
                value: '${metrics.unassignedIdeas}',
              ),
              _metric(
                icon: AppIcons.judges,
                label: 'Assignments',
                value: '${metrics.totalAssignments}',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_busy) const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: LinearProgressIndicator(minHeight: 2),
        ),
        WorkspaceCollapsibleSection(
          title: _kind.entriesLabel,
          icon: _kind.entriesIcon,
          count: _assignments.rows.length,
          child: _assignments.rows.isEmpty
              ? Text(
                  'No $entries registered.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                )
              : Column(
                  children: _assignments.rows
                      .map(
                        (IdeathonJudgeAssignmentRow row) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _IdeaAssignmentCard(
                            row: row,
                            judgeById: _assignments.judgeById,
                            canManage: _canManage,
                            onAssign: () => _openAssignSheet(row),
                            onRemove: _remove,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _lockedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(AppIcons.lock, size: 18, color: Color(0xFFB45309)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Judge assignments are locked because evaluation has started. Submitted scores are not changed from this view.',
              style: TextStyle(fontSize: 12, height: 1.4, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return EventLabeledField(
      icon: icon,
      label: label,
      value: value,
      labelWidth: _metricLabelWidth,
      valueStyle: _metricValueStyle,
      valueTextAlign: TextAlign.end,
      isLast: isLast,
    );
  }
}

class _IdeaAssignmentCard extends StatelessWidget {
  const _IdeaAssignmentCard({
    required this.row,
    required this.judgeById,
    required this.canManage,
    required this.onAssign,
    required this.onRemove,
  });

  final IdeathonJudgeAssignmentRow row;
  final Map<String, UserModel> judgeById;
  final bool canManage;
  final VoidCallback onAssign;
  final Future<void> Function(EvaluationAssignmentModel assignment) onRemove;

  @override
  Widget build(BuildContext context) {
    final String title =
        row.snapshot.ideaTitle.trim().isEmpty ? row.ideaId : row.snapshot.ideaTitle.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: row.isAssigned ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: EntityCardPills.workspace(
                    title,
                    ContextPillSemantic.idea,
                    () => WorkspaceNavigator.openIdea(context, row.ideaId),
                    icon: AppIcons.ideas,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: row.isAssigned ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  row.isAssigned ? 'Assigned' : 'Unassigned',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: row.isAssigned ? const Color(0xFF047857) : const Color(0xFFC2410C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (row.assignments.isEmpty)
            const Text(
              'No judges assigned.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: row.assignments.map((EvaluationAssignmentModel a) {
                final UserModel? user = judgeById[a.judgeId.trim()];
                final String name =
                    IdeathonJudgeAssignmentService.judgeDisplayName(judgeById, a.judgeId);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (user != null)
                      UserWorkspaceAvatar(
                        user: user,
                        radius: 11,
                        ringPadding: 1,
                        semantic: ContextPillSemantic.judge,
                        allowHoverScale: false,
                        enabled: user.userId.trim().isNotEmpty,
                        onTap: user.userId.trim().isEmpty
                            ? () {}
                            : () => WorkspaceNavigator.openUser(context, user.userId),
                      )
                    else
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Icon(AppIcons.judges, size: 13, color: Colors.grey.shade700),
                      ),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (canManage)
                      InkWell(
                        onTap: () => onRemove(a),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(AppIcons.remove, size: 16, color: Color(0xFF64748B)),
                        ),
                      ),
                  ],
                );
              }).toList(growable: false),
            ),
          if (canManage) ...<Widget>[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: ProblemWorkflowActionPill(
                label: 'Assign Judges',
                icon: AppIcons.judges,
                semantic: ProblemWorkflowPillSemantic.filledBrand,
                onTap: onAssign,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
