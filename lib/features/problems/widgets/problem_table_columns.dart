import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/problem_list_config.dart';
import '../models/problem_model.dart';
import '../models/problem_status.dart';
import '../services/problem_status_helpers.dart';
import '../validators/problem_submission_validators.dart';
import 'problem_context_pill.dart';
import 'problem_workflow_action_pill.dart';
import '../../dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../../../core/ui/common/card_overflow_menu.dart';
import '../../../core/ui/common/mobile_row_card_icon_action.dart';
import '../../../core/ui/data_view/data_table_column.dart';

const double _kPsTitleGap = 12;
const double _kDeptCategoryGap = 12;

/// Action bundle for [ProblemTableColumns] and [ProblemListRowCard].
class ProblemTableActions {
  const ProblemTableActions({
    required this.config,
    required this.ideaCountByProblemId,
    required this.orgDefaultMaxIdeas,
    required this.canEditFor,
    required this.canDeleteFor,
    required this.onOpenProblem,
    required this.onOpenDetails,
    required this.onSubmitIdea,
    required this.onAssignJudge,
    required this.onEditProblem,
    required this.onDeleteProblem,
    this.domainLabelById = const <String, String>{},
    this.onActivateProblem,
    this.onDeactivateProblem,
  });

  final ProblemListConfig config;
  final Map<String, int> ideaCountByProblemId;
  final int orgDefaultMaxIdeas;
  final bool Function(ProblemModel problem) canEditFor;
  final bool Function(ProblemModel problem) canDeleteFor;
  final void Function(ProblemModel problem) onOpenProblem;
  final void Function(ProblemModel problem) onOpenDetails;
  final void Function(ProblemModel problem) onSubmitIdea;
  final void Function(ProblemModel problem) onAssignJudge;
  final void Function(ProblemModel problem) onEditProblem;
  final void Function(ProblemModel problem) onDeleteProblem;
  final Map<String, String> domainLabelById;
  final void Function(ProblemModel problem)? onActivateProblem;
  final void Function(ProblemModel problem)? onDeactivateProblem;

  IdeaSubmissionGate gateFor(ProblemModel problem) => computeIdeaSubmissionGate(
        problem: problem,
        submittedCount: ideaCountByProblemId[problem.problemId] ?? 0,
        orgDefaultMaxIdeas: orgDefaultMaxIdeas,
      );
}

class _ProblemActionFlags {
  const _ProblemActionFlags({
    required this.showSubmit,
    required this.submitEnabled,
    required this.isClosed,
    required this.canManageStatus,
    required this.canAssignJudge,
    required this.canEdit,
    required this.canDelete,
    required this.canActivate,
    required this.canDeactivate,
  });

  final bool showSubmit;
  final bool submitEnabled;
  final bool isClosed;
  final bool canManageStatus;
  final bool canAssignJudge;
  final bool canEdit;
  final bool canDelete;
  final bool canActivate;
  final bool canDeactivate;

  factory _ProblemActionFlags.from({
    required ProblemModel problem,
    required ProblemTableActions actions,
  }) {
    final IdeaSubmissionGate gate = actions.gateFor(problem);
    final bool showSubmit = actions.config.canSubmitIdea;
    final bool submitEnabled = showSubmit && problem.isSubmissionOpen && gate.canSubmit;
    return _ProblemActionFlags(
      showSubmit: showSubmit,
      submitEnabled: submitEnabled,
      isClosed: showSubmit && !submitEnabled,
      canManageStatus: actions.config.canToggleActive,
      canAssignJudge: actions.config.canAssignJudge,
      canEdit: actions.canEditFor(problem),
      canDelete: actions.canDeleteFor(problem),
      canActivate: actions.config.canToggleActive &&
          (problem.status == ProblemStatus.draft || problem.status == ProblemStatus.inactive) &&
          actions.onActivateProblem != null,
      canDeactivate: actions.config.canToggleActive &&
          problem.status == ProblemStatus.active &&
          actions.onDeactivateProblem != null,
    );
  }
}

/// Per-feature column factory for the Problem Statements dashboard.
abstract final class ProblemTableColumns {
  static List<DataTableColumn<ProblemModel>> build({
    required ProblemListConfig config,
    required ProblemTableActions actions,
  }) {
    final Set<ProblemSortType> enabledSorts = config.enabledSorts;

    return <DataTableColumn<ProblemModel>>[
      DataTableColumn<ProblemModel>(
        label: 'Problem',
        flex: 3,
        minWidth: 112,
        gapAfter: _kPsTitleGap,
        sortKey: enabledSorts.contains(ProblemSortType.psNumber) ? 'psNumber' : null,
        cell: (BuildContext context, ProblemModel problem) => _ProblemIdCell(problem: problem),
      ),
      DataTableColumn<ProblemModel>(
        label: 'Title',
        flex: 10,
        minWidth: 180,
        sortKey: enabledSorts.contains(ProblemSortType.titleAZ) ? 'title' : null,
        cell: (BuildContext context, ProblemModel problem) {
          final String title = problem.title.trim().isEmpty ? 'Untitled' : problem.title.trim();
          return InkWell(
            onTap: () => actions.onOpenDetails(problem),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                  height: 1.35,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0x334F46E5),
                ),
              ),
            ),
          );
        },
      ),
      DataTableColumn<ProblemModel>(
        label: 'Department',
        flex: 3,
        minWidth: 100,
        gapAfter: _kDeptCategoryGap,
        sortKey: enabledSorts.contains(ProblemSortType.department) ? 'department' : null,
        cell: (BuildContext context, ProblemModel problem) {
          final String department = problem.departmentDisplayName.trim().isEmpty
              ? '—'
              : problem.departmentDisplayName.trim();
          return Text(
            department,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          );
        },
      ),
      DataTableColumn<ProblemModel>(
        label: 'Domain',
        flex: 3,
        minWidth: 100,
        cell: (BuildContext context, ProblemModel problem) {
          final String domainId = problem.domainId.trim();
          final String domain = domainId.isEmpty
              ? '—'
              : (actions.domainLabelById[domainId] ?? '—');
          return Text(
            domain,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          );
        },
      ),
      DataTableColumn<ProblemModel>(
        label: 'Category',
        flex: 2,
        minWidth: 76,
        sortKey: enabledSorts.contains(ProblemSortType.category) ? 'category' : null,
        cell: (BuildContext context, ProblemModel problem) {
          final String category = problem.category.trim().isEmpty ? '—' : problem.category.trim();
          return Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          );
        },
      ),
      DataTableColumn<ProblemModel>(
        label: 'Ideas',
        flex: 2,
        minWidth: 76,
        align: Alignment.center,
        sortKey: enabledSorts.contains(ProblemSortType.ideasCount) ? 'ideas' : null,
        cell: (BuildContext context, ProblemModel problem) {
          final IdeaSubmissionGate gate = actions.gateFor(problem);
          return Text(
            '${gate.submittedCount}/${gate.effectiveMaxIdeas}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          );
        },
      ),
      DataTableColumn<ProblemModel>(
        label: 'Deadline',
        flex: 2,
        minWidth: 92,
        align: Alignment.center,
        sortKey: enabledSorts.contains(ProblemSortType.deadline) ? 'deadline' : null,
        cell: (BuildContext context, ProblemModel problem) => _DeadlineCell(problem: problem),
      ),
      DataTableColumn<ProblemModel>(
        label: 'Actions',
        flex: 3,
        minWidth: 180,
        align: Alignment.centerLeft,
        cell: (BuildContext context, ProblemModel problem) => _ProblemRowActionArea(
          problem: problem,
          actions: actions,
        ),
      ),
    ];
  }
}

class _ProblemIdCell extends StatelessWidget {
  const _ProblemIdCell({required this.problem});

  final ProblemModel problem;

  @override
  Widget build(BuildContext context) {
    final ProblemStatus status = problem.status;
    final Color statusColor = ProblemStatusHelpers.color(status);
    final String label = ProblemContextPill.resolveLabel(
      problemNumber: problem.problemNumber,
      problemId: problem.problemId,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Tooltip(
          message: ProblemStatusHelpers.label(status),
          child: Icon(
            ProblemStatusHelpers.icon(status),
            size: 18,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact card for mobile problem statements list.
class ProblemListRowCard extends StatelessWidget {
  const ProblemListRowCard({
    super.key,
    required this.problem,
    required this.actions,
  });

  final ProblemModel problem;
  final ProblemTableActions actions;

  @override
  Widget build(BuildContext context) {
    final String title = problem.title.trim().isEmpty ? 'Untitled' : problem.title.trim();
    final String problemLabel = ProblemContextPill.resolveLabel(
      problemNumber: problem.problemNumber,
      problemId: problem.problemId,
    );
    final String category = problem.category.trim().isEmpty ? '—' : problem.category.trim();
    final IdeaSubmissionGate gate = actions.gateFor(problem);
    final _ProblemActionFlags flags = _ProblemActionFlags.from(
      problem: problem,
      actions: actions,
    );
    final List<Widget> primaryPills = _buildPrimaryProblemActionPills(
      problem: problem,
      actions: actions,
      flags: flags,
    );
    final List<Widget> iconActions = _buildProblemMobileIconActions(
      problem: problem,
      actions: actions,
      flags: flags,
    );
    final bool iconsOnRow3 = primaryPills.isEmpty && iconActions.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(AppIcons.problems, size: 20, color: Color(0xFF4A67FF)),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => actions.onOpenDetails(problem),
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    title,
                    style: MobileRowCardStyles.title.copyWith(
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (problemLabel != '—')
                _ProblemCardMetaLine(
                  icon: AppIcons.problems,
                  label: problemLabel,
                ),
              _ProblemCardMetaLine(
                icon: AppIcons.orgType,
                label: category,
              ),
              if ((actions.domainLabelById[problem.domainId.trim()] ?? '').isNotEmpty)
                _ProblemCardMetaLine(
                  icon: AppIcons.domains,
                  label: actions.domainLabelById[problem.domainId.trim()]!,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _ProblemCardMetaLine(
                      icon: AppIcons.ideas,
                      label: '${gate.submittedCount}/${gate.effectiveMaxIdeas}',
                    ),
                    _ProblemCardMetaLine(
                      icon: AppIcons.clock,
                      label: _formatDeadline(problem),
                    ),
                  ],
                ),
              ),
              if (iconsOnRow3)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: spacedMobileRowCardIconActions(iconActions),
                ),
            ],
          ),
          if (primaryPills.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: primaryPills,
                    ),
                  ),
                ),
                if (iconActions.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: spacedMobileRowCardIconActions(iconActions),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProblemCardMetaLine extends StatelessWidget {
  const _ProblemCardMetaLine({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

String _formatDeadline(ProblemModel problem) {
  if (problem.ideaSubmissionDeadline == null) return '—';
  final DateTime d = problem.ideaSubmissionDeadline!;
  return '${d.day} ${kMonthNames[d.month - 1]} ${d.year}';
}

List<Widget> _buildPrimaryProblemActionPills({
  required ProblemModel problem,
  required ProblemTableActions actions,
  required _ProblemActionFlags flags,
}) {
  final List<Widget> pills = <Widget>[];
  if (flags.canActivate) {
    pills.add(
      ProblemWorkflowActionPill(
        label: 'Activate',
        icon: AppIcons.problemStatusActive,
        semantic: ProblemWorkflowPillSemantic.primary,
        onTap: () => actions.onActivateProblem?.call(problem),
        tooltip: problem.status == ProblemStatus.inactive ? 'Reactivate problem' : 'Activate problem',
      ),
    );
  }
  if (flags.canDeactivate) {
    pills.add(
      ProblemWorkflowActionPill(
        label: 'Deactivate',
        icon: AppIcons.problemStatusInactive,
        semantic: ProblemWorkflowPillSemantic.pending,
        onTap: () => actions.onDeactivateProblem?.call(problem),
        tooltip: 'Deactivate problem',
      ),
    );
  }
  if (flags.showSubmit && flags.submitEnabled) {
    pills.add(
      ProblemWorkflowActionPill(
        label: 'Idea',
        showPlusPrefix: true,
        contentIcon: AppIcons.ideas,
        semantic: ProblemWorkflowPillSemantic.filledBrand,
        onTap: () => actions.onSubmitIdea(problem),
        tooltip: 'Submit idea',
      ),
    );
  }
  if (flags.isClosed) {
    pills.add(
      const ProblemWorkflowActionPill(
        label: 'Closed',
        icon: AppIcons.problemStatusInactive,
        semantic: ProblemWorkflowPillSemantic.closed,
        enabled: false,
        tooltip: 'Submissions closed',
      ),
    );
  }
  return pills;
}

List<CardOverflowMenuAction> _buildProblemOverflowActions({
  required _ProblemActionFlags flags,
}) {
  return <CardOverflowMenuAction>[
    if (flags.canEdit)
      const CardOverflowMenuAction(
        value: 'edit',
        icon: AppIcons.edit,
        label: 'Edit Problem',
      ),
    if (flags.canAssignJudge)
      const CardOverflowMenuAction(
        value: 'assign_judge',
        icon: AppIcons.judges,
        label: 'Assign Judge',
      ),
    if (flags.canDelete)
      const CardOverflowMenuAction(
        value: 'delete',
        icon: AppIcons.remove,
        label: 'Delete Problem',
        danger: true,
      ),
  ];
}

void _handleProblemMenuAction({
  required String value,
  required ProblemModel problem,
  required ProblemTableActions actions,
}) {
  switch (value) {
    case 'edit':
      actions.onEditProblem(problem);
    case 'assign_judge':
      actions.onAssignJudge(problem);
    case 'delete':
      actions.onDeleteProblem(problem);
  }
}

List<Widget> _buildProblemMobileIconActions({
  required ProblemModel problem,
  required ProblemTableActions actions,
  required _ProblemActionFlags flags,
}) {
  final List<Widget> icons = <Widget>[];
  if (flags.canEdit) {
    icons.add(
      MobileRowCardIconAction(
        tooltip: 'Edit Problem',
        icon: AppIcons.edit,
        onTap: () => actions.onEditProblem(problem),
      ),
    );
  }
  if (flags.canAssignJudge) {
    icons.add(
      MobileRowCardIconAction(
        tooltip: 'Assign Judge',
        icon: AppIcons.judges,
        onTap: () => actions.onAssignJudge(problem),
      ),
    );
  }
  if (flags.canDelete) {
    icons.add(
      MobileRowCardIconAction(
        tooltip: 'Delete Problem',
        icon: AppIcons.remove,
        onTap: () => actions.onDeleteProblem(problem),
        foregroundColor: MobileRowCardIconActionMetrics.dangerForegroundColor,
      ),
    );
  }
  return icons;
}

class _DeadlineCell extends StatelessWidget {
  const _DeadlineCell({required this.problem});

  final ProblemModel problem;

  @override
  Widget build(BuildContext context) {
    String deadlineDayMonth = '—';
    String deadlineYear = '';
    if (problem.ideaSubmissionDeadline != null) {
      final DateTime d = problem.ideaSubmissionDeadline!;
      deadlineDayMonth = '${d.day} ${kMonthNames[d.month - 1]}';
      deadlineYear = '${d.year}';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          deadlineDayMonth,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            height: 1.2,
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        if (deadlineYear.isNotEmpty)
          Text(
            deadlineYear,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.2,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}

class _ProblemRowActionArea extends StatelessWidget {
  const _ProblemRowActionArea({
    required this.problem,
    required this.actions,
  });

  final ProblemModel problem;
  final ProblemTableActions actions;

  @override
  Widget build(BuildContext context) {
    final _ProblemActionFlags flags = _ProblemActionFlags.from(
      problem: problem,
      actions: actions,
    );
    final List<Widget> primaryPills = _buildPrimaryProblemActionPills(
      problem: problem,
      actions: actions,
      flags: flags,
    );
    final List<CardOverflowMenuAction> menuActions = _buildProblemOverflowActions(
      flags: flags,
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ...primaryPills,
        if (menuActions.isNotEmpty)
          CardOverflowMenuButton(
            tooltip: 'Problem actions',
            dividersBefore: const <String>{'delete'},
            actions: menuActions,
            onSelected: (String value) => _handleProblemMenuAction(
              value: value,
              problem: problem,
              actions: actions,
            ),
          ),
      ],
    );
  }
}
