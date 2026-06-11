import 'package:flutter/material.dart';

import '../services/idea_status_helpers.dart';
import '../../../constants/app_icons.dart';
import '../models/idea_list_config.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../services/idea_query_service.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../widgets/common/card_overflow_menu.dart';
import '../../../widgets/common/context_pill_theme.dart';
import '../../../widgets/common/entity_card_pills.dart';
import '../../../widgets/common/mobile_row_card_icon_action.dart';
import '../../../widgets/common/mobile_row_card_pill.dart';
import '../../../widgets/data_view/data_table_column.dart';
import '../../problems/widgets/problem_context_pill.dart';
import '../../problems/widgets/problem_workflow_action_pill.dart';

const double _kLeadingColumnGap = 12;

/// Action bundle for [IdeaTableColumns] and [IdeaListRowCard].
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

class _IdeaActionFlags {
  const _IdeaActionFlags({
    required this.showPay,
    required this.canEval,
    required this.canAssignJudge,
    required this.hasAttachments,
    required this.hasPayment,
    required this.canEvalView,
    required this.hasScore,
  });

  final bool showPay;
  final bool canEval;
  final bool canAssignJudge;
  final bool hasAttachments;
  final bool hasPayment;
  final bool canEvalView;
  final bool hasScore;

  factory _IdeaActionFlags.from(IdeaListItem item, IdeaListConfig config) {
    return _IdeaActionFlags(
      showPay: config.canUploadPayment && item.canUploadPayment && item.team != null,
      canEval: config.canEvaluate && item.idea.status != IdeaStatus.draft,
      canAssignJudge: config.canAssignJudge,
      hasAttachments: item.attachmentCount > 0,
      hasPayment: item.payment != null,
      canEvalView: IdeaTableColumns.canOpenEvaluation(item),
      hasScore: item.score?.score != null,
    );
  }
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
        minWidth: 240,
        gapAfter: _kLeadingColumnGap,
        sortKey: enabledSorts.contains(IdeaSortType.newest) ? 'newest' : null,
        cell: (BuildContext context, IdeaListItem item) => _IdeaTitleCell(
          item: item,
          onOpenIdea: () => actions.onOpenIdea(item),
        ),
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
          final Widget pill = teamId.isEmpty
              ? EntityCardPills.meta(teamLabel, icon: AppIcons.teams)
              : EntityCardPills.workspace(
                  teamLabel,
                  ContextPillSemantic.team,
                  () => actions.onOpenTeam(item),
                  icon: AppIcons.teams,
                );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pill,
          );
        },
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Problem',
        flex: 2,
        minWidth: 136,
        gapAfter: _kLeadingColumnGap,
        cell: (BuildContext context, IdeaListItem item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: _ProblemIdPill(
            item: item,
            onOpenProblem: () => actions.onOpenProblem(item),
          ),
        ),
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
        label: 'Actions',
        flex: 2,
        minWidth: 112,
        align: Alignment.centerLeft,
        cell: (BuildContext context, IdeaListItem item) => _IdeaRowActionsCell(
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
        item.idea.status == IdeaStatus.shortlisted ||
        item.idea.status == IdeaStatus.underEvaluation;
  }
}

class _IdeaTitleCell extends StatelessWidget {
  const _IdeaTitleCell({
    required this.item,
    required this.onOpenIdea,
  });

  final IdeaListItem item;
  final VoidCallback onOpenIdea;

  @override
  Widget build(BuildContext context) {
    final IdeaStatus status = item.idea.status;
    final Color statusColor = IdeaStatusHelpers.color(status);
    final String title = item.idea.ideaTitle.trim().isEmpty
        ? 'Untitled Idea'
        : item.idea.ideaTitle.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Tooltip(
          message: IdeaStatusHelpers.label(status),
          child: Icon(
            IdeaStatusHelpers.icon(status),
            size: 18,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: onOpenIdea,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A67FF),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF4A67FF),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
    final String label = ProblemContextPill.resolveLabel(
      problemNumber: idea.problemNumber,
      problemId: problemId,
    );
    if (label == '—') return const _MutedDash();
    return ProblemContextPill.fromIdentifiers(
      problemNumber: idea.problemNumber,
      problemId: problemId,
      onTap: onOpenProblem,
      compact: true,
      fitContent: true,
      enabled: problemId.isNotEmpty,
      allowHoverScale: false,
      padding: ProblemContextPill.tableCellPadding,
    );
  }
}

class _IdeaRowActionsCell extends StatelessWidget {
  const _IdeaRowActionsCell({
    required this.item,
    required this.config,
    required this.actions,
  });

  final IdeaListItem item;
  final IdeaListConfig config;
  final IdeaTableActions actions;

  @override
  Widget build(BuildContext context) {
    final _IdeaActionFlags flags = _IdeaActionFlags.from(item, config);
    final List<Widget> inline = _buildPrimaryActionPills(
      item: item,
      actions: actions,
      flags: flags,
    );

    final List<CardOverflowMenuAction> menuActions = _buildOverflowMenuActions(
      item: item,
      actions: actions,
      flags: flags,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: inline,
          ),
        ),
        if (menuActions.isNotEmpty)
          CardOverflowMenuButton(
            tooltip: 'More actions',
            actions: menuActions,
            onSelected: (String value) => _handleMenuAction(value),
          ),
      ],
    );
  }

  void _handleMenuAction(String value) {
    _handleIdeaMenuAction(value: value, item: item, actions: actions);
  }

}

List<CardOverflowMenuAction> _buildOverflowMenuActions({
  required IdeaListItem item,
  required IdeaTableActions actions,
  required _IdeaActionFlags flags,
}) {
  return <CardOverflowMenuAction>[
    if (flags.canAssignJudge && actions.onAssignJudge != null)
      const CardOverflowMenuAction(
        value: 'assign_judge',
        icon: AppIcons.judges,
        label: 'Assign Judge',
      ),
    if (flags.canEval)
      const CardOverflowMenuAction(
        value: 'evaluate',
        icon: AppIcons.scoring,
        label: 'Evaluate',
      ),
    if (flags.hasAttachments)
      const CardOverflowMenuAction(
        value: 'attachments',
        icon: AppIcons.attachments,
        label: 'View Attachments',
      ),
    if (flags.hasPayment)
      const CardOverflowMenuAction(
        value: 'payment',
        icon: AppIcons.payments,
        label: 'View Payment',
      ),
    if (flags.canEvalView)
      const CardOverflowMenuAction(
        value: 'evaluation',
        icon: AppIcons.statusEvaluated,
        label: 'View Evaluation',
      ),
  ];
}

void _handleIdeaMenuAction({
  required String value,
  required IdeaListItem item,
  required IdeaTableActions actions,
}) {
  switch (value) {
    case 'assign_judge':
      actions.onAssignJudge?.call(item);
    case 'evaluate':
      actions.onEvaluate(item);
    case 'attachments':
      actions.onOpenAttachments(item);
    case 'payment':
      actions.onOpenPayment(item);
    case 'evaluation':
      actions.onOpenEvaluation(item);
  }
}

List<Widget> _buildPrimaryActionPills({
  required IdeaListItem item,
  required IdeaTableActions actions,
  required _IdeaActionFlags flags,
}) {
  if (!flags.showPay) return const <Widget>[];
  return <Widget>[
    ProblemWorkflowActionPill(
      label: 'Upload Payment',
      icon: AppIcons.payments,
      semantic: ProblemWorkflowPillSemantic.primary,
      onTap: () => actions.onUploadPayment(item),
    ),
  ];
}

/// Compact card for mobile ideas list — mirrors evaluation results row cards.
class IdeaListRowCard extends StatelessWidget {
  const IdeaListRowCard({
    super.key,
    required this.item,
    required this.config,
    required this.actions,
  });

  final IdeaListItem item;
  final IdeaListConfig config;
  final IdeaTableActions actions;

  @override
  Widget build(BuildContext context) {
    final IdeaStatus status = item.idea.status;
    final String title = item.idea.ideaTitle.trim().isEmpty
        ? 'Untitled Idea'
        : item.idea.ideaTitle.trim();
    final String teamLabel =
        item.teamName.trim().isEmpty ? 'Team' : item.teamName.trim();
    final String problemId = item.idea.problemId.trim();
    final String problemLabel = ProblemContextPill.resolveLabel(
      problemNumber: item.idea.problemNumber,
      problemId: problemId,
    );
    final String teamId = (item.team?.teamId ?? item.idea.teamId).trim();
    final _IdeaActionFlags flags = _IdeaActionFlags.from(item, config);
    final double? score = item.score?.score;
    final bool canOpenEvaluation = IdeaTableColumns.canOpenEvaluation(item);
    final List<Widget> actionPills = _buildPrimaryActionPills(
      item: item,
      actions: actions,
      flags: flags,
    );
    final List<Widget> iconActions = _buildMobileIconActions(
      item: item,
      actions: actions,
      flags: flags,
    );
    final bool iconsOnRow3 = actionPills.isEmpty && iconActions.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(AppIcons.ideas, size: 20, color: Color(0xFF4A67FF)),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => actions.onOpenIdea(item),
                  borderRadius: BorderRadius.circular(4),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MobileRowCardStyles.title,
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
                _MobileCardMetaLine(
                  icon: AppIcons.problems,
                  label: problemLabel,
                  onTap: problemId.isNotEmpty ? () => actions.onOpenProblem(item) : null,
                ),
              _MobileCardMetaLine(
                icon: AppIcons.teams,
                label: teamLabel,
                onTap: teamId.isNotEmpty ? () => actions.onOpenTeam(item) : null,
              ),
              MobileRowCardPill.status(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (score != null) ...<Widget>[
                MobileRowCardPill.evaluation(
                  score: score,
                  onTap: canOpenEvaluation
                      ? () => actions.onOpenEvaluation(item)
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              MobileRowCardPill.attachments(
                count: item.attachmentCount,
                onTap: item.attachmentCount > 0
                    ? () => actions.onOpenAttachments(item)
                    : null,
              ),
              if (iconsOnRow3) ...<Widget>[
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: spacedMobileRowCardIconActions(iconActions),
                ),
              ],
            ],
          ),
          if (actionPills.isNotEmpty) ...<Widget>[
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
                      children: actionPills,
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

List<Widget> _buildMobileIconActions({
  required IdeaListItem item,
  required IdeaTableActions actions,
  required _IdeaActionFlags flags,
}) {
  final List<Widget> icons = <Widget>[];
  if (flags.canAssignJudge && actions.onAssignJudge != null) {
    icons.add(
      MobileRowCardIconAction(
        tooltip: 'Assign Judge',
        icon: AppIcons.judges,
        onTap: () => actions.onAssignJudge?.call(item),
      ),
    );
  }
  if (flags.canEval) {
    icons.add(
      MobileRowCardIconAction(
        tooltip: 'Evaluate',
        icon: AppIcons.scoring,
        onTap: () => actions.onEvaluate(item),
      ),
    );
  }
  if (flags.hasPayment) {
    icons.add(
      MobileRowCardIconAction(
        tooltip: 'View Payment',
        icon: AppIcons.payments,
        onTap: () => actions.onOpenPayment(item),
      ),
    );
  }
  return icons;
}

class _MobileCardMetaLine extends StatelessWidget {
  const _MobileCardMetaLine({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
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
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: content,
    );
  }
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
