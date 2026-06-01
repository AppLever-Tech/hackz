import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../models/idea_list_config.dart';
import '../models/idea_model.dart';
import '../services/idea_query_service.dart';
import '../../../widgets/common/card_overflow_menu.dart';
import '../../../widgets/common/context_pill.dart';
import '../../../widgets/common/context_pill_theme.dart';
import '../../../widgets/common/entity_card_pills.dart';
import '../../../widgets/data_view/data_table_column.dart';

const double _kLeadingColumnGap = 12;

/// Action bundle for [IdeaTableColumns].
class IdeaTableActions {
  const IdeaTableActions({
    required this.onOpenIdea,
    required this.onOpenTeam,
    required this.onOpenProblem,
    required this.onOpenPayment,
    required this.onOpenEvaluation,
    required this.onOpenAttachments,
    required this.onEvaluate,
    required this.onUploadPayment,
    this.onAssignJudge,
  });

  final void Function(IdeaListItem item) onOpenIdea;
  final void Function(IdeaListItem item) onOpenTeam;
  final void Function(IdeaListItem item) onOpenProblem;
  final void Function(IdeaListItem item) onOpenPayment;
  final void Function(IdeaListItem item) onOpenEvaluation;
  final void Function(IdeaListItem item) onOpenAttachments;
  final void Function(IdeaListItem item) onEvaluate;
  final void Function(IdeaListItem item) onUploadPayment;
  final void Function(IdeaListItem item)? onAssignJudge;
}

/// Per-feature column factory for the Ideas dashboard.
abstract final class IdeaTableColumns {
  static List<DataTableColumn<IdeaListItem>> build({
    required IdeaListConfig config,
    required IdeaTableActions actions,
  }) {
    final Set<IdeaSortType> enabledSorts = config.enabledSorts;
    return <DataTableColumn<IdeaListItem>>[
      DataTableColumn<IdeaListItem>(
        label: 'Idea',
        flex: 5,
        minWidth: 220,
        gapAfter: _kLeadingColumnGap,
        sortKey: enabledSorts.contains(IdeaSortType.newest) ? 'newest' : null,
        cell: (BuildContext context, IdeaListItem item) {
          final String title = item.idea.ideaTitle.trim().isEmpty
              ? 'Untitled Idea'
              : item.idea.ideaTitle.trim();
          return InkWell(
            onTap: () => actions.onOpenIdea(item),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67FF),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF4A67FF),
                ),
              ),
            ),
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Team',
        flex: 3,
        minWidth: 140,
        gapAfter: _kLeadingColumnGap,
        cell: (BuildContext context, IdeaListItem item) {
          final String teamLabel =
              item.teamName.trim().isEmpty ? 'Team' : item.teamName.trim();
          final String teamId = (item.team?.teamId ?? item.idea.teamId).trim();
          if (teamId.isEmpty) {
            return EntityCardPills.meta(teamLabel, icon: AppIcons.teams);
          }
          return EntityCardPills.workspace(
            teamLabel,
            ContextPillSemantic.team,
            () => actions.onOpenTeam(item),
            icon: AppIcons.teams,
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Problem',
        flex: 2,
        minWidth: 100,
        gapAfter: _kLeadingColumnGap,
        cell: (BuildContext context, IdeaListItem item) =>
            _ProblemIdPill(item: item, onOpenProblem: () => actions.onOpenProblem(item)),
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Status',
        flex: 3,
        minWidth: 140,
        gapAfter: _kLeadingColumnGap,
        sortKey: enabledSorts.contains(IdeaSortType.status) ? 'status' : null,
        cell: (BuildContext context, IdeaListItem item) =>
            _StatusCell(status: item.idea.status),
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Score',
        flex: 1,
        minWidth: 80,
        align: Alignment.center,
        sortKey: enabledSorts.contains(IdeaSortType.score) ? 'score' : null,
        cell: (BuildContext context, IdeaListItem item) {
          final double? score = item.score?.score;
          if (score == null) return const _MutedDash();
          final bool clickable = canOpenEvaluation(item);
          final Widget chip = _ScoreChip(value: score);
          if (!clickable) return chip;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => actions.onOpenEvaluation(item),
            child: chip,
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: '',
        flex: 1,
        minWidth: 56,
        align: Alignment.center,
        cell: (BuildContext context, IdeaListItem item) => _IdeaRowActionsMenu(
          item: item,
          config: config,
          actions: actions,
        ),
      ),
    ];
  }

  static bool canOpenEvaluation(IdeaListItem item) {
    if (item.score != null) return true;
    return item.idea.status == IdeaStatus.evaluated ||
        item.idea.status == IdeaStatus.approved ||
        item.idea.status == IdeaStatus.underReview;
  }
}

class _ProblemIdPill extends StatelessWidget {
  const _ProblemIdPill({
    required this.item,
    required this.onOpenProblem,
  });

  final IdeaListItem item;
  final VoidCallback onOpenProblem;

  @override
  Widget build(BuildContext context) {
    final IdeaModel idea = item.idea;
    final String problemId = idea.problemId.trim();
    final String number = idea.problemNumber.trim();
    final String label = number.isNotEmpty ? number : problemId;
    if (label.isEmpty) return const _MutedDash();
    return ContextPill(
      label: label,
      semantic: ContextPillSemantic.problem,
      onTap: problemId.isEmpty ? () {} : onOpenProblem,
      compact: true,
      fitContent: true,
      enabled: problemId.isNotEmpty,
    );
  }
}

/// Row-level ⋮ menu — same [CardOverflowMenuButton] styling as problem statements.
class _IdeaRowActionsMenu extends StatelessWidget {
  const _IdeaRowActionsMenu({
    required this.item,
    required this.config,
    required this.actions,
  });

  final IdeaListItem item;
  final IdeaListConfig config;
  final IdeaTableActions actions;

  @override
  Widget build(BuildContext context) {
    final bool showPay =
        config.canUploadPayment && item.canUploadPayment && item.team != null;
    final bool canEval =
        config.canEvaluate && item.idea.status != IdeaStatus.pendingSubmission;
    final String teamId = (item.team?.teamId ?? item.idea.teamId).trim();
    final bool hasAttachments = item.attachmentCount > 0;
    final bool hasPayment = item.payment != null;
    final bool canEvalView = IdeaTableColumns.canOpenEvaluation(item);

    final List<CardOverflowMenuAction> menuActions = <CardOverflowMenuAction>[
      const CardOverflowMenuAction(
        value: 'idea',
        icon: AppIcons.preview,
        label: 'View Idea',
      ),
      if (config.canAssignJudge && actions.onAssignJudge != null)
        const CardOverflowMenuAction(
          value: 'assign_judge',
          icon: AppIcons.judges,
          label: 'Assign Judge',
        ),
      if (teamId.isNotEmpty)
        const CardOverflowMenuAction(
          value: 'team',
          icon: AppIcons.teams,
          label: 'Open Team',
        ),
      if (item.idea.problemId.trim().isNotEmpty)
        const CardOverflowMenuAction(
          value: 'problem',
          icon: AppIcons.problems,
          label: 'Open Problem',
        ),
      if (canEval)
        const CardOverflowMenuAction(
          value: 'evaluate',
          icon: AppIcons.scoring,
          label: 'Evaluate',
        ),
      if (showPay)
        const CardOverflowMenuAction(
          value: 'upload_payment',
          icon: AppIcons.payments,
          label: 'Upload Payment',
        ),
      if (hasAttachments)
        const CardOverflowMenuAction(
          value: 'attachments',
          icon: AppIcons.attachments,
          label: 'View Attachments',
        ),
      if (hasPayment)
        const CardOverflowMenuAction(
          value: 'payment',
          icon: AppIcons.payments,
          label: 'View Payment',
        ),
      if (canEvalView)
        const CardOverflowMenuAction(
          value: 'evaluation',
          icon: AppIcons.statusEvaluated,
          label: 'View Evaluation',
        ),
    ];

    return CardOverflowMenuButton(
      tooltip: 'Idea actions',
      actions: menuActions,
      onSelected: (String value) {
        switch (value) {
          case 'idea':
            actions.onOpenIdea(item);
          case 'assign_judge':
            actions.onAssignJudge?.call(item);
          case 'team':
            actions.onOpenTeam(item);
          case 'problem':
            actions.onOpenProblem(item);
          case 'evaluate':
            actions.onEvaluate(item);
          case 'upload_payment':
            actions.onUploadPayment(item);
          case 'attachments':
            actions.onOpenAttachments(item);
          case 'payment':
            actions.onOpenPayment(item);
          case 'evaluation':
            actions.onOpenEvaluation(item);
        }
      },
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.status});
  final IdeaStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(_iconFor(status), size: 14, color: _colorFor(status)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _labelFor(status),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _colorFor(status),
            ),
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(IdeaStatus s) => switch (s) {
        IdeaStatus.pendingSubmission => AppIcons.statusPendingSubmission,
        IdeaStatus.submitted => AppIcons.statusSubmitted,
        IdeaStatus.underReview => AppIcons.statusUnderReview,
        IdeaStatus.evaluated => AppIcons.statusEvaluated,
        IdeaStatus.approved => AppIcons.statusApproved,
        IdeaStatus.rejected => AppIcons.statusRejected,
      };

  static Color _colorFor(IdeaStatus s) => switch (s) {
        IdeaStatus.pendingSubmission => const Color(0xFF94A3B8),
        IdeaStatus.submitted => const Color(0xFF7C3AED),
        IdeaStatus.underReview => const Color(0xFFEA580C),
        IdeaStatus.evaluated => const Color(0xFF0EA5E9),
        IdeaStatus.approved => const Color(0xFF059669),
        IdeaStatus.rejected => const Color(0xFFDC2626),
      };

  static String _labelFor(IdeaStatus s) => switch (s) {
        IdeaStatus.pendingSubmission => 'Pending',
        IdeaStatus.submitted => 'Submitted',
        IdeaStatus.underReview => 'Under Review',
        IdeaStatus.evaluated => 'Evaluated',
        IdeaStatus.approved => 'Approved',
        IdeaStatus.rejected => 'Rejected',
      };
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD9A8)),
      ),
      child: Text(
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB45309),
        ),
      ),
    );
  }
}

class _MutedDash extends StatelessWidget {
  const _MutedDash();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '—',
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
