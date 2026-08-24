import 'package:flutter/material.dart';
import 'package:hackz/core/theme/app_icons.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/features/events/widgets/event_detail_section.dart';
import 'package:hackz/features/events/widgets/event_lifecycle_section.dart';
import 'package:hackz/features/idea/services/idea_status_helpers.dart';
import 'package:hackz/features/ideathons/services/ideathon_details_loader.dart';

class IdeathonIdeasTab extends StatelessWidget {
  const IdeathonIdeasTab({super.key, required this.vm});

  final IdeathonDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.ideas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No ideas are registered for this Ideathon.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
      children: <Widget>[
        EventDetailSection(
          title: 'Paid & Confirmed Ideas',
          icon: AppIcons.ideas,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Ideas that were paid and confirmed when this Ideathon was created. '
                'Open Idea, Problem, or Team in the right-side workspace.',
                style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < vm.ideas.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 8),
                _ideaRow(context, vm.ideas[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _ideaRow(BuildContext context, IdeathonIdeaEntry row) {
    return EventEntryRow(
      ideaLabel: row.ideaTitle.isEmpty ? row.ideaId : row.ideaTitle,
      onIdeaTap: () => WorkspaceNavigator.openIdea(context, row.ideaId),
      status: row.idea == null
          ? const _PlainChip(label: 'Registered', color: Color(0xFF64748B))
          : _PlainChip(
              label: IdeaStatusHelpers.label(row.idea!.status),
              color: IdeaStatusHelpers.color(row.idea!.status),
            ),
      problemLabel: row.problemTitle,
      onProblemTap: row.problemId.isEmpty ? null : () => WorkspaceNavigator.openProblem(context, row.problemId),
      teamLabel: row.teamName,
      onTeamTap: row.teamId.isEmpty ? null : () => WorkspaceNavigator.openTeam(context, row.teamId),
    );
  }
}

class _PlainChip extends StatelessWidget {
  const _PlainChip({required this.label, required this.color});

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
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
