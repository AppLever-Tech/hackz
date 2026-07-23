import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../constants/problem_constants.dart';
import '../../widgets/problem_source_pill.dart';
import '../../widgets/problem_status_pill.dart';
import '../../../../core/ui/common/rich_tabs.dart';
import '../../workspace/problem_workspace_loader.dart';
import 'lifecycle_tab.dart';
import 'problem_details_tab.dart';
import 'submitted_idea_tab.dart';

/// Tabbed body for the problem statement details pane.
class ProblemStatementDetailsBody extends StatelessWidget {
  const ProblemStatementDetailsBody({
    super.key,
    required this.vm,
  });

  final ProblemWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final String psNumber = vm.problem.problemNumber.trim();
    final String? category = ProblemConstants.resolveCategory(vm.problem.category.trim());

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
                      icon: AppIcons.departments,
                      label: vm.problem.departmentDisplayName.trim().isEmpty
                          ? '—'
                          : vm.problem.departmentDisplayName.trim(),
                      color: const Color(0xFF475569),
                    ),
                    if (vm.domain != null)
                      _MetaChip(
                        icon: AppIcons.domains,
                        label: vm.domain!.name.trim().isEmpty
                            ? vm.domain!.code
                            : vm.domain!.name.trim(),
                        color: const Color(0xFF0F766E),
                      ),
                    if (category != null)
                      _MetaChip(
                        icon: AppIcons.orgType,
                        label: category,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ProblemStatusPill(status: vm.problem.status, compact: false),
                    ProblemSourcePill(createdSource: vm.problem.createdSource, compact: false),
            ],
          ),
        ),
        Expanded(
          child: RichTabs(
              tabs: <RichTabItem>[
                const RichTabItem('Problem Details'),
                RichTabItem('Submitted Ideas', count: vm.allIdeas.isEmpty ? null : vm.allIdeas.length),
                const RichTabItem('Problem Lifecycle'),
              ],
              children: <Widget>[
                ProblemDetailsTab(vm: vm),
                SubmittedIdeaTab(vm: vm),
                LifecycleTab(vm: vm),
              ],
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
