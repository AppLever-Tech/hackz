import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/dashboard/dashboard_metric_chips.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../../evaluations/assignments/models/evaluation_assignment_model.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';
import '../../user/models/user_model.dart';
import '../services/ideathon_judge_assignment_service.dart';
import 'ideathon_assign_judges_sheet.dart';
import 'ideathon_status_pill.dart';

enum _AssignmentFilter { all, assigned, unassigned }

/// Event Details tab: full judge-assignment UI (search, filters, overview).
class IdeathonJudgeAssignmentsPanel extends StatefulWidget {
  const IdeathonJudgeAssignmentsPanel({
    super.key,
    required this.vm,
    this.actor,
  });

  final IdeathonJudgeAssignmentViewModel vm;
  final UserModel? actor;

  @override
  State<IdeathonJudgeAssignmentsPanel> createState() =>
      _IdeathonJudgeAssignmentsPanelState();
}

class _IdeathonJudgeAssignmentsPanelState
    extends State<IdeathonJudgeAssignmentsPanel> {
  late IdeathonJudgeAssignmentViewModel _vm;
  bool _busy = false;
  String _search = '';
  _AssignmentFilter _filter = _AssignmentFilter.all;

  @override
  void initState() {
    super.initState();
    _vm = widget.vm;
  }

  @override
  void didUpdateWidget(covariant IdeathonJudgeAssignmentsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm != widget.vm) _vm = widget.vm;
  }

  bool get _canManage =>
      IdeathonJudgeAssignmentService.canManageAssignments(widget.actor) && !_vm.evaluationLocked;

  bool get _isAdmin => IdeathonJudgeAssignmentService.canManageAssignments(widget.actor);

  Future<void> _reload() async {
    final IdeathonJudgeAssignmentViewModel next =
        await IdeathonJudgeAssignmentService.load(_vm.ideathon.ideathonId);
    if (!mounted) return;
    setState(() => _vm = next);
  }

  List<IdeathonJudgeAssignmentRow> get _filteredRows {
    final String q = _search.trim().toLowerCase();
    return _vm.rows.where((IdeathonJudgeAssignmentRow row) {
      switch (_filter) {
        case _AssignmentFilter.assigned:
          if (!row.isAssigned) return false;
        case _AssignmentFilter.unassigned:
          if (row.isAssigned) return false;
        case _AssignmentFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      final String hay = <String>[
        row.snapshot.ideaTitle,
        row.snapshot.problemTitle,
        row.snapshot.teamName,
        row.idea.ideaTitle,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList(growable: false);
  }

  Future<void> _openAssignSheet(IdeathonJudgeAssignmentRow row) async {
    if (_vm.evaluationLocked) {
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
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return IdeathonAssignJudgesSheet(
          row: row,
          evaluators: _vm.evaluators,
          initiallySelected: selected,
          onSave: (Set<String> judgeIds) async {
            final Set<String> toAdd = judgeIds.difference(selected);
            if (toAdd.isEmpty) return;
            await IdeathonJudgeAssignmentService.assignJudgesToIdea(
              actor: widget.actor!,
              ideathonId: _vm.ideathon.ideathonId,
              ideaId: row.ideaId,
              judgeIds: toAdd,
            );
          },
        );
      },
    );
    if (saved == true && mounted) {
      await _reload();
      if (!mounted) return;
      FeedbackService.showSuccess(
        context,
        title: 'Judges assigned',
        message: 'Assignments saved for this Ideathon idea.',
      );
    }
  }

  Future<void> _remove(EvaluationAssignmentModel assignment) async {
    if (!_canManage) return;
    setState(() => _busy = true);
    try {
      await IdeathonJudgeAssignmentService.removeAssignment(
        actor: widget.actor!,
        ideathonId: _vm.ideathon.ideathonId,
        assignmentId: assignment.assignmentId,
      );
      await _reload();
      if (!mounted) return;
      FeedbackService.showSuccess(context, title: 'Judge removed', message: 'Assignment updated for this Ideathon.');
    } catch (e) {
      if (!mounted) return;
      FeedbackService.showError(context, title: 'Unable to remove', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideathon = _vm.ideathon;
    final metrics = _vm.metrics;
    final String templateName =
        _vm.template.templateName.trim().isEmpty ? _vm.template.templateId : _vm.template.templateName.trim();

    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        ResponsiveMetricGrid(
          chips: <DashboardMetricChipData>[
            DashboardMetricChipData.single(
              label: 'Registered Ideas',
              value: '${metrics.totalIdeas}',
              color: const Color(0xFF4A67FF),
              icon: AppIcons.ideas,
            ),
            DashboardMetricChipData.single(
              label: 'Assigned',
              value: '${metrics.assignedIdeas}',
              color: const Color(0xFF059669),
              icon: AppIcons.workflowApproved,
            ),
            DashboardMetricChipData.single(
              label: 'Unassigned',
              value: '${metrics.unassignedIdeas}',
              color: const Color(0xFFEA580C),
              icon: AppIcons.info,
            ),
            DashboardMetricChipData.single(
              label: 'Assignments',
              value: '${metrics.totalAssignments}',
              color: const Color(0xFF7C3AED),
              icon: AppIcons.judges,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_vm.evaluationLocked) ...<Widget>[
          Container(
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
          ),
          const SizedBox(height: 12),
        ],
        if (_vm.workloads.isNotEmpty) ...<Widget>[
          const Text(
            'Judge workload',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vm.workloads
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
                      '${w.displayName} · ${w.ideaCount} idea${w.ideaCount == 1 ? '' : 's'}',
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
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: kDashboardCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(ideathon.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              IdeathonStatusPill(status: ideathon.status, compact: false),
              const SizedBox(height: 10),
              _detailRow('Starts', formatDateTime(ideathon.startDateTime.toLocal())),
              _detailRow('Ends', formatDateTime(ideathon.endDateTime.toLocal())),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    width: 110,
                    child: Text(
                      'Evaluation Template',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: EntityCardPills.workspace(
                        templateName,
                        ContextPillSemantic.evaluationTemplate,
                        () => WorkspaceNavigator.openEvaluationTemplate(
                          context,
                          _vm.template.templateId,
                        ),
                        icon: AppIcons.scoring,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Explicitly assign judges to paid ideas registered for this Ideathon. Judges are not assigned automatically. The evaluation template is fixed for the event.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              if (_vm.evaluationLocked) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  'View only — assignments locked after evaluation started.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
                ),
              ] else if (!_isAdmin) ...<Widget>[
                const SizedBox(height: 8),
                const Text(
                  'View only — Department Admin can assign or reassign judges.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (String v) => setState(() => _search = v),
          style: HackzInputDecoration.fieldTextStyle,
          decoration: HackzInputDecoration.decorate(
            hintText: 'Search ideas, teams, problems…',
            prefixIcon: const Icon(AppIcons.search, size: 18, color: HackzInputDecoration.iconColor),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _filterChip(label: 'All', selected: _filter == _AssignmentFilter.all, onTap: () => setState(() => _filter = _AssignmentFilter.all)),
            _filterChip(
              label: 'Assigned',
              selected: _filter == _AssignmentFilter.assigned,
              onTap: () => setState(() => _filter = _AssignmentFilter.assigned),
            ),
            _filterChip(
              label: 'Unassigned',
              selected: _filter == _AssignmentFilter.unassigned,
              onTap: () => setState(() => _filter = _AssignmentFilter.unassigned),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (_filteredRows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No Ideathon ideas match your filters.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          )
        else
          ..._filteredRows.map(
            (IdeathonJudgeAssignmentRow row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IdeaAssignmentCard(
                row: row,
                judgeById: _vm.judgeById,
                canManage: _canManage,
                onAssign: () => _openAssignSheet(row),
                onRemove: _remove,
              ),
            ),
          ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE0E7FF),
      checkmarkColor: const Color(0xFF4338CA),
      side: BorderSide(color: selected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
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
      padding: const EdgeInsets.all(12),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Text(
            '${row.snapshot.problemTitle} · ${row.snapshot.teamName}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          if (row.assignments.isEmpty)
            const Text(
              'No judges assigned for this Ideathon idea.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: row.assignments.map((EvaluationAssignmentModel a) {
                final String name =
                    IdeathonJudgeAssignmentService.judgeDisplayName(judgeById, a.judgeId);
                return InputChip(
                  label: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  avatar: Icon(AppIcons.judges, size: 14, color: Colors.grey.shade700),
                  onDeleted: canManage ? () => onRemove(a) : null,
                  deleteIconColor: const Color(0xFF64748B),
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                );
              }).toList(growable: false),
            ),
          if (canManage) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ProblemWorkflowActionPill(
                label: row.isAssigned ? 'Assign more judges' : 'Assign judges',
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
