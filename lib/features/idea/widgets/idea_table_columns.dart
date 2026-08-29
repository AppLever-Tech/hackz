import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/idea_list_config.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import '../services/idea_query_service.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/common/mobile_row_card_pill.dart';
import '../../../core/ui/data_view/data_table_column.dart';
import '../../problems/widgets/problem_context_pill.dart';
import 'idea_event_pills.dart';

const double _kLeadingColumnGap = 12;

/// Action bundle for [IdeaTableColumns] and [IdeaListRowCard].
class IdeaTableActions {
  const IdeaTableActions({
    required this.onOpenIdea,
    required this.onOpenTeam,
    required this.onOpenProblem,
    required this.onOpenEvent,
  });

  final void Function(IdeaListItem item) onOpenIdea;
  final void Function(IdeaListItem item) onOpenTeam;
  final void Function(IdeaListItem item) onOpenProblem;
  final void Function(IdeaListItem item, String eventId) onOpenEvent;
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
        label: 'Idea Status',
        flex: 2,
        minWidth: 110,
        gapAfter: _kLeadingColumnGap,
        cell: (BuildContext context, IdeaListItem item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: MobileRowCardPill.status(status: item.idea.status),
        ),
      ),
      DataTableColumn<IdeaListItem>(
        label: 'Events',
        flex: 4,
        minWidth: 160,
        align: Alignment.centerLeft,
        cell: (BuildContext context, IdeaListItem item) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: IdeaEventPills(
            events: item.events,
            onOpenEvent: (event) => actions.onOpenEvent(item, event.eventId),
          ),
        ),
      ),
    ];
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
    final String title = item.idea.ideaTitle.trim().isEmpty
        ? 'Untitled Idea'
        : item.idea.ideaTitle.trim();

    return InkWell(
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
    if (label == '—') {
      return const Text(
        '—',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
      );
    }
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

/// Compact card for mobile ideas list.
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (teamId.isEmpty)
                EntityCardPills.meta(teamLabel, icon: AppIcons.teams)
              else
                EntityCardPills.workspace(
                  teamLabel,
                  ContextPillSemantic.team,
                  () => actions.onOpenTeam(item),
                  icon: AppIcons.teams,
                ),
              if (problemLabel != '—')
                ProblemContextPill.fromIdentifiers(
                  problemNumber: item.idea.problemNumber,
                  problemId: problemId,
                  onTap: () => actions.onOpenProblem(item),
                  compact: true,
                  fitContent: true,
                  enabled: problemId.isNotEmpty,
                  allowHoverScale: false,
                ),
              MobileRowCardPill.status(status: item.idea.status),
            ],
          ),
          if (item.events.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            IdeaEventPills(
              events: item.events,
              onOpenEvent: (event) => actions.onOpenEvent(item, event.eventId),
            ),
          ],
        ],
      ),
    );
  }
}
