import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                MobileRowCardPill.status(status: idea.status),
                const SizedBox(width: 8),
                if (teamId.isNotEmpty)
                  ContextPill(
                    label: teamLabel,
                    semantic: ContextPillSemantic.team,
                    icon: AppIcons.teams,
                    onTap: () => WorkspaceNavigator.openTeam(context, teamId),
                    compact: true,
                    fitContent: true,
                  )
                else
                  EntityCardPills.meta(teamLabel, icon: AppIcons.teams),
                if (problemId.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  ProblemContextPill.fromIdentifiers(
                    problemNumber: idea.problemNumber,
                    problemId: problemId,
                    onTap: () => IdeaWorkspace.openProblemFromIdea(context, vm.ideaVm),
                    compact: true,
                    fitContent: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: RichTabs(
            useSwitcherOnMobile: false,
            tabs: const <RichTabItem>[
              RichTabItem('Idea Details', icon: AppIcons.ideas),
              RichTabItem('Idea Lifecycle', icon: AppIcons.insights),
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
