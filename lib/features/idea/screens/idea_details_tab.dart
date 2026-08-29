import 'package:flutter/material.dart';

import '../../user/models/user_model.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FormValueRow(
            labelWidth: fieldLabelWidth,
            label: 'Team',
            labelAlignment: Alignment.centerLeft,
            child: teamId.isNotEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: ContextPill(
                      label: teamLabel.isEmpty ? 'Team' : teamLabel,
                      semantic: ContextPillSemantic.team,
                      icon: AppIcons.teams,
                      onTap: () => WorkspaceNavigator.openTeam(context, teamId),
                      compact: true,
                      fitContent: true,
                    ),
                  )
                : Text(
                    teamLabel.isEmpty ? '—' : teamLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
          ),
          const SizedBox(height: 8),
          FormValueRow(
            labelWidth: fieldLabelWidth,
            label: 'Members',
            labelAlignment: Alignment.centerLeft,
            crossAxisAlignment: CrossAxisAlignment.start,
            labelTopInset: 7,
            child: roster.isEmpty
                ? const Text(
                    'No team members listed.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (int i = 0; i < roster.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: 8),
                        _TeamMemberRow(
                          user: roster[i],
                          organizationName: _orgNameFor(roster[i]),
                          isLeader: vm.teamLeader != null && roster[i].userId == vm.teamLeader!.userId,
                          stackOrganization: isMobile,
                        ),
                      ],
                    ],
                  ),
          ),
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
      clipBehavior: Clip.none,
      children: <Widget>[
        if (isMobile) ...<Widget>[
          ideaCard,
          const SizedBox(height: 8),
          teamCard,
        ] else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: ideaCard),
                const SizedBox(width: 8),
                Expanded(child: teamCard),
              ],
            ),
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
      clipBehavior: Clip.none,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 12,
        isMobile ? 8 : 10,
        isMobile ? 10 : 12,
        isMobile ? 12 : 16,
      ),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
    this.stackOrganization = false,
  });

  final UserModel user;
  final String organizationName;
  final bool isLeader;
  final bool stackOrganization;

  @override
  Widget build(BuildContext context) {
    final String name = user.displayName.trim().isEmpty ? user.userId : user.displayName.trim();
    final bool canOpen = user.userId.trim().isNotEmpty;
    final String org = organizationName.trim();
    final Widget nameText = Text.rich(
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
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    final Widget? college = org.isEmpty
        ? null
        : PageHeaderContextPill.fromItem(PageHeaderContextItem.organization(org));

    Widget identity({required bool expandName}) {
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
          if (expandName) Expanded(child: nameText) else nameText,
        ],
      );
    }

    if (college == null) return identity(expandName: true);

    if (stackOrganization) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          identity(expandName: true),
          const SizedBox(height: 4),
          college,
        ],
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = !constraints.hasBoundedWidth || constraints.maxWidth < 280;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              identity(expandName: true),
              const SizedBox(height: 4),
              college,
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: identity(expandName: true)),
            const SizedBox(width: 8),
            college,
          ],
        );
      },
    );
  }
}
