import 'package:flutter/material.dart';

import '../../user/models/user_model.dart';
import '../../organization/models/department_model.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../workspace/idea_workspace_loader.dart';
import '../widgets/innovation_assets_section.dart';
import '../widgets/idea_event_pills.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';
import '../workspace/idea_workspace.dart';

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
    final String departmentName = DepartmentModel.byCode(idea.teamDepartmentCode)?.name ??
        (idea.teamDepartmentCode.trim().isEmpty ? '—' : idea.teamDepartmentCode.trim());

    final bool isMobile = ResponsiveHelper.isMobile(context);
    final double labelWidth = isMobile ? 92 : 112;
    final List<UserModel> members = vm.teamMembers
        .where((UserModel m) => m.userId.trim() != vm.team.teamLeaderId.trim())
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
      children: <Widget>[
        _card(
          context: context,
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
              _labeledContextPillRow(
                context: context,
                labelWidth: labelWidth,
                label: 'Submitted by',
                pillLabel: vm.submittedByName,
                semantic: ContextPillSemantic.user,
                onTap: () {
                  final String userId = (vm.submittedBy?.userId ?? idea.createdBy).trim();
                  if (userId.isEmpty) return;
                  WorkspaceNavigator.openUser(context, userId);
                },
                enabled: (vm.submittedBy?.userId ?? idea.createdBy).trim().isNotEmpty,
              ),
              _metaRow(
                context,
                labelWidth: labelWidth,
                label: 'Created',
                value: formatDateTime(idea.createdAt),
                isLast: true,
              ),
              const SizedBox(height: 10),
              InnovationAssetsSection(
                idea: idea,
                attachments: vm.attachments,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _card(
          context: context,
          title: 'Team',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (teamId.isNotEmpty)
                _labeledContextPillRow(
                  context: context,
                  labelWidth: labelWidth,
                  label: 'Team',
                  pillLabel: vm.teamName.trim().isEmpty ? teamId : vm.teamName.trim(),
                  semantic: ContextPillSemantic.team,
                  onTap: () => WorkspaceNavigator.openTeam(context, teamId),
                )
              else
                _metaRow(context, labelWidth: labelWidth, label: 'Team', value: vm.teamName),
              if (vm.teamLeader != null)
                _labeledContextPillRow(
                  context: context,
                  labelWidth: labelWidth,
                  label: 'Team Leader',
                  pillLabel: userDisplayName(vm.teamLeader!),
                  semantic: ContextPillSemantic.user,
                  onTap: () => WorkspaceNavigator.openUser(context, vm.teamLeader!.userId),
                )
              else
                _metaRow(context, labelWidth: labelWidth, label: 'Team Leader', value: '—'),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: labelWidth,
                      child: const Text(
                        'Members',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      child: members.isEmpty
                          ? const Text(
                              '—',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            )
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: members
                                  .map(
                                    (UserModel member) => ContextPill(
                                      label: userDisplayName(member),
                                      semantic: ContextPillSemantic.user,
                                      onTap: () => WorkspaceNavigator.openUser(context, member.userId),
                                      compact: true,
                                      fitContent: true,
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                  ],
                ),
              ),
              _metaRow(
                context,
                labelWidth: labelWidth,
                label: 'Department',
                value: departmentName,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _card(
          context: context,
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
        ),
      ],
    );
  }

  static Widget _card({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final bool isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 8 : 10),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  static Widget _labeledContextPillRow({
    required BuildContext context,
    required double labelWidth,
    required String label,
    required String pillLabel,
    required ContextPillSemantic semantic,
    required VoidCallback onTap,
    bool enabled = true,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Flexible(
            child: ContextPill(
              label: pillLabel,
              semantic: semantic,
              onTap: onTap,
              enabled: enabled,
              compact: true,
              fitContent: true,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _metaRow(
    BuildContext _, {
    required double labelWidth,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value.trim(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
