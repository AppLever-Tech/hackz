import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../../constants/status_styles.dart';
import '../../../widgets/common/rich_tabs.dart';
import '../../problems/screens/problem_statements/problem_details_tab.dart';
import '../services/idea_details_loader.dart';
import 'idea_details_tab.dart';
import 'idea_lifecycle_tab.dart';

/// Tabbed body for the idea details dashboard pane.
class IdeaDetailsBody extends StatelessWidget {
  const IdeaDetailsBody({super.key, required this.vm});

  final IdeaDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final idea = vm.ideaVm.idea;
    final String psNumber = idea.problemNumber.trim();
    final String statusLabel = StatusStyles.labelForIdeaStatus(idea.status);

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
              if (psNumber.isNotEmpty)
                _MetaChip(
                  icon: AppIcons.problems,
                  label: 'PS #$psNumber',
                  color: const Color(0xFF6A38FF),
                ),
              _MetaChip(
                icon: StatusStyles.iconForIdeaStatus(idea.status),
                label: statusLabel,
                color: StatusStyles.colorForIdeaStatus(idea.status),
              ),
              if (vm.ideaVm.teamName.trim().isNotEmpty)
                _MetaChip(
                  icon: AppIcons.teams,
                  label: vm.ideaVm.teamName.trim(),
                  color: const Color(0xFF475569),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: RichTabs(
              tabs: const <RichTabItem>[
                RichTabItem('Idea Details'),
                RichTabItem('Problem Details'),
                RichTabItem('Idea Lifecycle'),
              ],
              children: <Widget>[
                IdeaDetailsTab(vm: vm.ideaVm),
                ProblemDetailsTab(vm: vm.problemVm),
                IdeaLifecycleTab(vm: vm.ideaVm),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
