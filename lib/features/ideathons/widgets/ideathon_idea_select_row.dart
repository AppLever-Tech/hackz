import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../idea/models/idea_model.dart';
import '../../idea/services/idea_status_helpers.dart';
import '../../organization/models/department_model.dart';
import '../services/ideathon_team_eligibility.dart';

/// Compact premium selectable idea row for Ideathon creation.
class IdeathonIdeaSelectRow extends StatelessWidget {
  const IdeathonIdeaSelectRow({
    super.key,
    required this.idea,
    required this.selected,
    required this.onToggle,
    this.teamName = '',
    this.organisationName = '',
    this.origin,
  });

  final IdeaModel idea;
  final bool selected;
  final VoidCallback onToggle;
  final String teamName;
  final String organisationName;
  final IdeathonTeamOrigin? origin;

  @override
  Widget build(BuildContext context) {
    final bool compactWeb = !ResponsiveHelper.isMobile(context);
    final String title = idea.ideaTitle.trim().isEmpty ? idea.ideaId : idea.ideaTitle.trim();
    final String problemLabel = idea.problemNumber.trim().isNotEmpty
        ? idea.problemNumber.trim()
        : (idea.problemId.trim().isEmpty ? '—' : idea.problemId.trim());
    final String deptCode = DepartmentModel.resolveCode(idea.problemDepartmentCode);
    final String branch = deptCode.isEmpty ? '' : (DepartmentModel.byCode(deptCode)?.code ?? deptCode);
    final String team = teamName.trim();
    final String organisation = organisationName.trim();
    final bool showOrigin = origin != null && origin != IdeathonTeamOrigin.host;

    final Widget ideaPill = EntityCardPills.workspace(
      title,
      ContextPillSemantic.idea,
      () => WorkspaceNavigator.openIdea(context, idea.ideaId),
      icon: IdeaStatusHelpers.icon(idea.status),
    );
    final Widget problemPill = EntityCardPills.workspace(
      problemLabel,
      ContextPillSemantic.problem,
      idea.problemId.trim().isEmpty
          ? () {}
          : () => WorkspaceNavigator.openProblem(context, idea.problemId),
      icon: AppIcons.problems,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5F3FF) : const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFFC4B5FD) : const Color(0xFFE2E8F0),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: selected,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) => onToggle(),
                ),
              ),
              const SizedBox(width: 8),
              if (compactWeb) ...<Widget>[
                Flexible(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ideaPill,
                          if (team.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 6),
                            EntityCardPills.meta(team, icon: AppIcons.teams),
                          ],
                          if (organisation.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 6),
                            EntityCardPills.meta(organisation, icon: AppIcons.organizations),
                          ],
                          if (showOrigin) ...<Widget>[
                            const SizedBox(width: 6),
                            EntityCardPills.meta(origin!.pillLabel, icon: AppIcons.users),
                          ],
                          if (branch.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 6),
                            EntityCardPills.meta(branch, icon: AppIcons.departments),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                problemPill,
              ] else ...<Widget>[
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ideaPill,
                          if (team.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 6),
                            EntityCardPills.meta(team, icon: AppIcons.teams),
                          ],
                          if (organisation.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 6),
                            EntityCardPills.meta(organisation, icon: AppIcons.organizations),
                          ],
                          if (showOrigin) ...<Widget>[
                            const SizedBox(width: 6),
                            EntityCardPills.meta(origin!.pillLabel, icon: AppIcons.users),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                problemPill,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
