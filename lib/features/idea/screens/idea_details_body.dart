import 'package:flutter/material.dart';

import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/ui/common/mobile_row_card_pill.dart';
import '../../../core/ui/common/rich_tabs.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../problems/widgets/problem_context_pill.dart';
import '../services/idea_details_loader.dart';
import '../workspace/idea_workspace.dart';
import 'idea_details_tab.dart';
import 'idea_lifecycle_tab.dart';

/// Tabbed body for the idea details dashboard pane.
class IdeaDetailsBody extends StatelessWidget {
  const IdeaDetailsBody({super.key, required this.vm});

  final IdeaDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final idea = vm.ideaVm.idea;
    final String teamId = vm.ideaVm.team.teamId.trim().isNotEmpty
        ? vm.ideaVm.team.teamId.trim()
        : idea.teamId.trim();
    final String teamLabel = vm.ideaVm.teamName.trim().isEmpty ? 'Team' : vm.ideaVm.teamName.trim();
    final String problemId =
        vm.ideaVm.problem.problemId.trim().isEmpty ? idea.problemId.trim() : vm.ideaVm.problem.problemId.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              MobileRowCardPill.status(status: idea.status),
              if (teamId.isNotEmpty)
                ContextPill(
                  label: teamLabel,
                  semantic: ContextPillSemantic.team,
                  onTap: () => WorkspaceNavigator.openTeam(context, teamId),
                  compact: true,
                  fitContent: true,
                )
              else
                EntityCardPills.meta(teamLabel),
              if (problemId.isNotEmpty)
                ProblemContextPill.fromIdentifiers(
                  problemNumber: idea.problemNumber,
                  problemId: problemId,
                  onTap: () => IdeaWorkspace.openProblemFromIdea(context, vm.ideaVm),
                  compact: true,
                  fitContent: true,
                ),
            ],
          ),
        ),
        Expanded(
          child: RichTabs(
            tabs: const <RichTabItem>[
              RichTabItem('Idea Details'),
              RichTabItem('Idea Lifecycle'),
            ],
            children: <Widget>[
              IdeaDetailsTab(vm: vm.ideaVm),
              IdeaLifecycleTab(vm: vm.ideaVm),
            ],
          ),
        ),
      ],
    );
  }
}
