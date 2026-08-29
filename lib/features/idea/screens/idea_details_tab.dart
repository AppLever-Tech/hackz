import 'package:flutter/material.dart';

import '../../user/models/user_model.dart';
import '../../organization/models/department_model.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/form_value_row.dart';
import '../../../core/ui/common/page_header_context_pill.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../widgets/idea_event_pills.dart';
import '../widgets/innovation_assets_section.dart';
import '../workspace/idea_workspace.dart';
import '../workspace/idea_workspace_loader.dart';

/// Idea Details tab for [IdeaDetailsPane].
class IdeaDetailsTab extends StatelessWidget {
  const IdeaDetailsTab({super.key, required this.vm});

  final IdeaWorkspaceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final idea = vm.idea;
    final String title = idea.ideaTitle.trim().isEmpty ? 'Untitled innovation' : idea.ideaTitle.trim();
    final String description = idea.description.trim();
    final String teamId = vm.team.teamId.trim().isNotEmpty ? vm.team.teamId.trim() : idea.teamId.trim();
    final String teamLabel = vm.teamName.trim().isEmpty ? teamId : vm.teamName.trim();
    final String departmentName = DepartmentModel.byCode(idea.teamDepartmentCode)?.name ??
        (idea.teamDepartmentCode.trim().isEmpty ? '' : idea.teamDepartmentCode.trim());
    final bool isMobile = ResponsiveHelper.isMobile(context);
    const double fieldLabelWidth = 102;
    final List<UserModel> members = vm.teamMembers
        .where((UserModel m) => m.userId.trim() != vm.team.teamLeaderId.trim())
        .toList(growable: false);
    final List<UserModel> roster = <UserModel>[
      if (vm.teamLeader != null) vm.teamLeader!,
      ...members,
    ];

    final Widget ideaCard = _card(
      context: context,
      icon: AppIcons.ideas,
      title: 'Idea',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          FormValueRow(
            labelWidth: fieldLabelWidth,
            label: 'Submitted by',
            labelAlignment: Alignment.centerLeft,
            child: _submittedByValue(context),
          ),
          const SizedBox(height: 6),
          FormValueRow(
            labelWidth: fieldLabelWidth,
            label: 'Created',
            labelAlignment: Alignment.centerLeft,
            child: Text(
              formatDateTime(idea.createdAt),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 10),
          InnovationAssetsSection(
            idea: idea,
            attachments: vm.attachments,
          ),
        ],
      ),
    );

    final Widget teamCard = _card(
      context: context,
      icon: AppIcons.teams,
      title: 'Team',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: teamId.isNotEmpty
                ? ContextPill(
                    label: teamLabel.isEmpty ? 'Team' : teamLabel,
                    semantic: ContextPillSemantic.team,
                    icon: AppIcons.teams,
                    onTap: () => WorkspaceNavigator.openTeam(context, teamId),
                    compact: true,
                    fitContent: true,
                  )
                : Text(
                    teamLabel.isEmpty ? '—' : teamLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
          ),
          const SizedBox(height: 10),
          if (roster.isEmpty)
            const Text(
              'No team members listed.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            )
          else
            ...roster.asMap().entries.expand((MapEntry<int, UserModel> entry) {
              final bool isLeader = vm.teamLeader != null && entry.value.userId == vm.teamLeader!.userId;
              return <Widget>[
                if (entry.key > 0) const SizedBox(height: 8),
                _TeamMemberRow(
                  user: entry.value,
                  organizationName: _orgNameFor(entry.value),
                  isLeader: isLeader,
                ),
              ];
            }),
          if (departmentName.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PageHeaderContextPill.fromItem(PageHeaderContextItem.department(departmentName)),
            ),
          ],
        ],
      ),
    );

    final Widget eventsCard = _card(
      context: context,
      icon: AppIcons.ideathons,
      title: 'Event Participation',
      child: vm.eventParticipations.isEmpty
          ? const Text(
              'This idea has not participated in an event yet.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.4),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: vm.eventParticipations
                  .map(
                    (event) => IdeaEventParticipationRow(
                      event: event,
                      onOpenEvent: () => IdeaWorkspace.openEvent(context, event.eventId),
                    ),
                  )
                  .toList(growable: false),
            ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
      children: <Widget>[
        if (isMobile) ...<Widget>[
          ideaCard,
          const SizedBox(height: 8),
          teamCard,
        ] else
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.fill,
            columnWidths: const <int, TableColumnWidth>{
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
            },
            children: <TableRow>[
              TableRow(
                children: <Widget>[
                  Padding(padding: const EdgeInsets.only(right: 4), child: ideaCard),
                  Padding(padding: const EdgeInsets.only(left: 4), child: teamCard),
                ],
              ),
            ],
          ),
        const SizedBox(height: 8),
        eventsCard,
      ],
    );
  }

  String _orgNameFor(UserModel user) {
    if (user.organisationName.trim().isNotEmpty) return user.organisationName.trim();
    return vm.organizationName.trim();
  }

  Widget _submittedByValue(BuildContext context) {
    final UserModel? submittedBy = vm.submittedBy;
    final String fallbackName = vm.submittedByName.trim().isNotEmpty
        ? vm.submittedByName.trim()
        : (vm.idea.createdBy.trim().isEmpty ? '—' : vm.idea.createdBy.trim());
    if (submittedBy == null) {
      return Text(
        fallbackName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      );
    }
    final String name = submittedBy.displayName.trim().isEmpty ? submittedBy.userId : submittedBy.displayName.trim();
    final bool canOpen = submittedBy.userId.trim().isNotEmpty;
    return Row(
      children: <Widget>[
        UserWorkspaceAvatar(
          user: submittedBy,
          radius: 13,
          ringPadding: 2,
          allowHoverScale: false,
          enabled: canOpen,
          onTap: canOpen ? () => WorkspaceNavigator.openUser(context, submittedBy.userId) : () {},
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  static Widget _card({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final bool isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      width: double.infinity,
      alignment: Alignment.topLeft,
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 8 : 10),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TeamMemberRow extends StatelessWidget {
  const _TeamMemberRow({
    required this.user,
    required this.organizationName,
    this.isLeader = false,
  });

  final UserModel user;
  final String organizationName;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final String name = user.displayName.trim().isEmpty ? user.userId : user.displayName.trim();
    final bool canOpen = user.userId.trim().isNotEmpty;
    final String org = organizationName.trim();

    return Row(
      children: <Widget>[
        UserWorkspaceAvatar(
          user: user,
          radius: 13,
          ringPadding: 2,
          allowHoverScale: false,
          enabled: canOpen,
          onTap: canOpen ? () => WorkspaceNavigator.openUser(context, user.userId) : () {},
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (isLeader)
                        const TextSpan(
                          text: '  · Leader',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (org.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PageHeaderContextPill.fromItem(PageHeaderContextItem.organization(org)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
