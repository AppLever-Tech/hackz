import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../screens/common/dashboard_components.dart';
import '../../workspace/problem_workspace_loader.dart';
import '../../workspace/problem_stats_section.dart';
import 'submitted_ideas_table.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';

/// Submitted Ideas tab for [ProblemStatementDetailsScreen].
class SubmittedIdeaTab extends StatelessWidget {
  const SubmittedIdeaTab({super.key, required this.vm});

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: kDashboardCardDecoration,
          child: ProblemStatsSection(vm: vm),
        ),
        const SizedBox(height: 12),
        if (vm.allIdeas.isEmpty)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: kDashboardCardDecoration,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(AppIcons.ideas, size: 40, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text(
                    'No ideas submitted yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Innovation proposals for this problem statement will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: SubmittedIdeasTable(
              ideas: vm.allIdeas,
              onOpenIdea: (preview) => WorkspaceNavigator.openIdea(context, preview.idea.ideaId),
            ),
          ),
      ],
    );
  }
}
