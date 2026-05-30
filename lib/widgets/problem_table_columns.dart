import 'package:flutter/material.dart';

import '../constants/app_icons.dart';
import '../features/problems/models/problem_list_config.dart';
import '../features/problems/models/problem_model.dart';
import '../features/problems/validators/problem_submission_validators.dart';
import '../features/problems/widgets/problem_workflow_action_pill.dart';
import '../responsive/responsive_helper.dart';
import '../utils/common_helpers.dart';
import 'common/card_overflow_menu.dart';
import 'common/context_pill.dart';
import 'common/context_pill_theme.dart';
import 'data_view/data_table_column.dart';

const double _kPsTitleGap = 12;
const double _kDeptCategoryGap = 12;

/// Action bundle for [ProblemTableColumns].
class ProblemTableActions {
  const ProblemTableActions({
    required this.config,
    required this.ideaCountByProblemId,
    required this.orgDefaultMaxIdeas,
    required this.canEditFor,
    required this.onOpenProblem,
    required this.onOpenDetails,
    required this.onSubmitIdea,
    required this.onAssignJudge,
    required this.onEditProblem,
    required this.onDeleteProblem,
  });

  final ProblemListConfig config;
  final Map<String, int> ideaCountByProblemId;
  final int orgDefaultMaxIdeas;
  final bool Function(ProblemModel problem) canEditFor;
  final void Function(ProblemModel problem) onOpenProblem;
  final void Function(ProblemModel problem) onOpenDetails;
  final void Function(ProblemModel problem) onSubmitIdea;
  final void Function(ProblemModel problem) onAssignJudge;
  final void Function(ProblemModel problem) onEditProblem;
  final void Function(ProblemModel problem) onDeleteProblem;
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
        label: 'PS #',
        flex: 3,
        minWidth: 132,
        gapAfter: _kPsTitleGap,
        sortKey: enabledSorts.contains(ProblemSortType.psNumber) ? 'psNumber' : null,
        cell: (BuildContext context, ProblemModel problem) {
          final String number =
              problem.problemNumber.trim().isEmpty ? '—' : problem.problemNumber.trim();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ActiveStatusDot(active: problem.isActive),
              const SizedBox(width: 6),
              Flexible(
                child: ContextPill(
                  label: number,
                  semantic: ContextPillSemantic.problem,
                  onTap: () => actions.onOpenProblem(problem),
                  compact: true,
                  fitContent: true,
                ),
              ),
            ],
          );
        },
      ),
      DataTableColumn<ProblemModel>(
        label: 'Title',
        flex: 10,
        minWidth: 220,
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
        minWidth: 120,
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
        label: 'Theme',
        flex: 3,
        minWidth: 96,
        sortKey: _newestSortKey(enabledSorts),
        cell: (BuildContext context, ProblemModel problem) {
          final String theme = problem.theme.trim().isEmpty ? '—' : problem.theme.trim();
          return Text(
            theme,
            softWrap: true,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
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
          final IdeaSubmissionGate gate = computeIdeaSubmissionGate(
            problem: problem,
            submittedCount: actions.ideaCountByProblemId[problem.problemId] ?? 0,
            orgDefaultMaxIdeas: actions.orgDefaultMaxIdeas,
          );
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
        label: '',
        flex: 3,
        minWidth: 180,
        align: Alignment.centerRight,
        cell: (BuildContext context, ProblemModel problem) => _ProblemRowActionArea(
          problem: problem,
          gate: computeIdeaSubmissionGate(
            problem: problem,
            submittedCount: actions.ideaCountByProblemId[problem.problemId] ?? 0,
            orgDefaultMaxIdeas: actions.orgDefaultMaxIdeas,
          ),
          canSubmitIdea: actions.config.canSubmitIdea,
          canAssignJudge: actions.config.canAssignJudge,
          canEdit: actions.canEditFor(problem),
          canDelete: actions.config.canToggleActive,
          onSubmitIdea: () => actions.onSubmitIdea(problem),
          onOpenDetails: () => actions.onOpenDetails(problem),
          onAssignJudge: actions.config.canAssignJudge ? () => actions.onAssignJudge(problem) : null,
          onEdit: actions.canEditFor(problem) ? () => actions.onEditProblem(problem) : null,
          onDelete: actions.config.canToggleActive ? () => actions.onDeleteProblem(problem) : null,
        ),
      ),
    ];
  }

  static String? _newestSortKey(Set<ProblemSortType> enabledSorts) {
    if (enabledSorts.contains(ProblemSortType.newest) ||
        enabledSorts.contains(ProblemSortType.oldest)) {
      return 'newest';
    }
    return null;
  }
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

class _ActiveStatusDot extends StatelessWidget {
  const _ActiveStatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color dot = active ? const Color(0xFF059669) : const Color(0xFFCBD5E1);
    return Tooltip(
      message: active ? 'Active' : 'Inactive',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
    );
  }
}

class _ProblemRowActionArea extends StatelessWidget {
  const _ProblemRowActionArea({
    required this.problem,
    required this.gate,
    required this.canSubmitIdea,
    required this.canAssignJudge,
    required this.canEdit,
    required this.canDelete,
    required this.onSubmitIdea,
    required this.onOpenDetails,
    required this.onAssignJudge,
    required this.onEdit,
    required this.onDelete,
  });

  final ProblemModel problem;
  final IdeaSubmissionGate gate;
  final bool canSubmitIdea;
  final bool canAssignJudge;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onSubmitIdea;
  final VoidCallback onOpenDetails;
  final VoidCallback? onAssignJudge;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final bool showSubmit = canSubmitIdea;
    final bool submitEnabled = showSubmit && problem.isActive && gate.canSubmit;
    final bool isClosed = showSubmit && !submitEnabled;
    final List<CardOverflowMenuAction> actions = <CardOverflowMenuAction>[
      const CardOverflowMenuAction(
        value: 'details',
        icon: AppIcons.preview,
        label: 'View Details',
      ),
      if (canAssignJudge && onAssignJudge != null)
        const CardOverflowMenuAction(
          value: 'assign_judge',
          icon: AppIcons.judges,
          label: 'Assign Judge',
        ),
      if (canEdit && onEdit != null)
        const CardOverflowMenuAction(
          value: 'edit',
          icon: AppIcons.edit,
          label: 'Edit Problem',
        ),
      if (canDelete && onDelete != null)
        const CardOverflowMenuAction(
          value: 'delete',
          icon: AppIcons.remove,
          label: 'Delete Problem',
          danger: true,
        ),
    ];

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: ResponsiveHelper.isMobile(context) ? 4 : 6,
      runSpacing: 4,
      children: <Widget>[
        if (showSubmit && submitEnabled)
          ProblemWorkflowActionPill(
            label: 'Idea',
            showPlusPrefix: true,
            contentIcon: AppIcons.ideas,
            semantic: ProblemWorkflowPillSemantic.filledBrand,
            onTap: onSubmitIdea,
            tooltip: 'Submit idea',
          ),
        if (isClosed)
          const ProblemWorkflowActionPill(
            label: 'Closed',
            icon: AppIcons.statusInactive,
            semantic: ProblemWorkflowPillSemantic.closed,
            enabled: false,
            tooltip: 'Submissions closed',
          ),
        CardOverflowMenuButton(
          tooltip: 'Problem actions',
          dividersBefore: const <String>{'delete'},
          actions: actions,
          onSelected: (String value) {
            switch (value) {
              case 'details':
                onOpenDetails();
              case 'assign_judge':
                onAssignJudge?.call();
              case 'edit':
                onEdit?.call();
              case 'delete':
                onDelete?.call();
            }
          },
        ),
      ],
    );
  }
}
