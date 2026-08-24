import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';
import 'package:hackz/core/ui/data_view/data_table_column.dart';
import 'package:hackz/core/ui/data_view/data_table_view.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/idea/services/idea_status_helpers.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';

class IdeathonIdeasTab extends StatelessWidget {
  const IdeathonIdeasTab({super.key, required this.vm});

  final IdeathonDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    const Widget intro = Padding(
      padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(AppIcons.ideas, size: 16, color: Color(0xFF334155)),
              SizedBox(width: 6),
              Text(
                'Paid & Confirmed Ideas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Ideas that were paid and confirmed when this Ideathon was created. '
            'Open Idea, Problem, or Team in the right-side workspace.',
            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );

    if (vm.ideas.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          intro,
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No ideas are registered for this Ideathon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        intro,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: DataTableView<IdeathonIdeaEntry>(
            items: vm.ideas,
            columns: <DataTableColumn<IdeathonIdeaEntry>>[
              DataTableColumn<IdeathonIdeaEntry>(
                label: 'Idea',
                flex: 5,
                minWidth: 220,
                gapAfter: 12,
                cell: (BuildContext context, IdeathonIdeaEntry row) => Align(
                  alignment: Alignment.centerLeft,
                  child: ContextPill(
                    label: _ideaLabel(row),
                    semantic: ContextPillSemantic.idea,
                    onTap: () => WorkspaceNavigator.openIdea(context, row.ideaId),
                    compact: true,
                    fitContent: false,
                    expandWidth: false,
                    allowHoverScale: false,
                  ),
                ),
              ),
              DataTableColumn<IdeathonIdeaEntry>(
                label: 'Problem',
                flex: 5,
                minWidth: 220,
                gapAfter: 12,
                cell: (BuildContext context, IdeathonIdeaEntry row) => Align(
                  alignment: Alignment.centerLeft,
                  child: ContextPill(
                    label: row.problemTitle.isEmpty ? '—' : row.problemTitle,
                    semantic: ContextPillSemantic.problem,
                    onTap: row.problemId.isEmpty
                        ? () {}
                        : () => WorkspaceNavigator.openProblem(context, row.problemId),
                    enabled: row.problemId.isNotEmpty,
                    compact: true,
                    fitContent: false,
                    expandWidth: false,
                    allowHoverScale: false,
                  ),
                ),
              ),
              DataTableColumn<IdeathonIdeaEntry>(
                label: 'Team',
                flex: 2,
                minWidth: 140,
                gapAfter: 12,
                cell: (BuildContext context, IdeathonIdeaEntry row) => Align(
                  alignment: Alignment.centerLeft,
                  child: ContextPill(
                    label: row.teamName.isEmpty ? '—' : row.teamName,
                    semantic: ContextPillSemantic.team,
                    onTap: row.teamId.isEmpty ? () {} : () => WorkspaceNavigator.openTeam(context, row.teamId),
                    enabled: row.teamId.isNotEmpty,
                    compact: true,
                    fitContent: true,
                    expandWidth: false,
                    allowHoverScale: false,
                  ),
                ),
              ),
              DataTableColumn<IdeathonIdeaEntry>(
                label: 'Status',
                flex: 1,
                minWidth: 88,
                align: Alignment.center,
                cell: (_, IdeathonIdeaEntry row) => Align(
                  alignment: Alignment.center,
                  child: _statusPill(row),
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }

  static String _ideaLabel(IdeathonIdeaEntry row) =>
      row.ideaTitle.isEmpty ? row.ideaId : row.ideaTitle;

  static Widget _statusPill(IdeathonIdeaEntry row) {
    if (row.idea == null) {
      return const _StatusChip(label: 'Registered', color: Color(0xFF64748B));
    }
    return _StatusChip(
      label: IdeaStatusHelpers.label(row.idea!.status),
      color: IdeaStatusHelpers.color(row.idea!.status),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
