import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/context_pill_theme.dart';
import '../../../core/ui/common/entity_card_pills.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../core/workspace/workspace_navigator.dart';
import '../../../core/workspace/workspace_theme.dart';
import '../../../utils/common_helpers.dart';
import '../../evaluations/workspace/evaluation_template_workspace.dart';
import '../../events/models/event_winner_entry.dart';
import '../../events/widgets/event_labeled_field.dart';
import '../../events/widgets/workspace_collapsible_section.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_idea_snapshot.dart';
import '../models/ideathon_model.dart';
import '../widgets/ideathon_event_workspace_header.dart';
import 'ideathon_workspace_loader.dart';

class IdeathonWorkspaceBody extends StatelessWidget {
  const IdeathonWorkspaceBody({
    super.key,
    required this.vm,
    this.onOpenJudgeAssignment,
    this.onOpenResults,
    this.onOpenPayments,
  });

  final IdeathonWorkspaceViewModel vm;
  final VoidCallback? onOpenJudgeAssignment;
  final VoidCallback? onOpenResults;
  final VoidCallback? onOpenPayments;

  static const double _labelWidth = 78;
  static const Color _winnerAccent = Color(0xFFC9A227);
  static const Color _runnerAccent = Color(0xFF8B9BB4);

  @override
  Widget build(BuildContext context) {
    final IdeathonModel event = vm.ideathon;
    final int peopleCount = vm.judges.length + vm.coordinators.length;

    return ListView(
      padding: WorkspaceTheme.bodyPadding(context),
      children: <Widget>[
        _eventOverview(context, event),
        const SizedBox(height: 14),
        WorkspaceCollapsibleSection(
          title: 'Judges and coordinators',
          icon: AppIcons.users,
          count: peopleCount,
          child: _people(context),
        ),
        const SizedBox(height: 10),
        WorkspaceCollapsibleSection(
          title: 'Ideas',
          icon: AppIcons.ideas,
          count: event.ideas.length,
          child: _ideas(context, event.ideas),
        ),
        const SizedBox(height: 10),
        WorkspaceCollapsibleSection(
          title: 'Event Payment',
          icon: AppIcons.payments,
          child: EntityCardPills.workspace(
            'Event Payments',
            ContextPillSemantic.payment,
            onOpenPayments ?? () {},
            enabled: onOpenPayments != null,
            icon: AppIcons.payments,
          ),
        ),
        const SizedBox(height: 10),
        WorkspaceCollapsibleSection(
          title: 'Judge assignment',
          icon: AppIcons.judges,
          child: EntityCardPills.workspace(
            'Judge assignment',
            ContextPillSemantic.judge,
            onOpenJudgeAssignment ?? () {},
            enabled: onOpenJudgeAssignment != null,
            icon: AppIcons.judges,
          ),
        ),
        const SizedBox(height: 10),
        WorkspaceCollapsibleSection(
          title: 'Evaluation Results',
          icon: AppIcons.results,
          child: EntityCardPills.workspace(
            'Ideathon evaluation results',
            ContextPillSemantic.evaluation,
            onOpenResults ?? () {},
            enabled: onOpenResults != null,
            icon: AppIcons.results,
          ),
        ),
        const SizedBox(height: 10),
        WorkspaceCollapsibleSection(
          title: 'Results',
          icon: AppIcons.leaderboard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _resultPlace(
                context,
                placeLabel: 'Winner',
                icon: Icons.emoji_events_rounded,
                accent: _winnerAccent,
                entry: vm.winner,
              ),
              const SizedBox(height: 10),
              _resultPlace(
                context,
                placeLabel: 'Runner-up',
                icon: Icons.military_tech_rounded,
                accent: _runnerAccent,
                entry: vm.runnerUp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eventOverview(BuildContext context, IdeathonModel event) {
    final String templateLabel = vm.evaluationTemplateName.trim().isEmpty
        ? (event.evaluationTemplateId.trim().isEmpty ? '—' : event.evaluationTemplateId.trim())
        : vm.evaluationTemplateName.trim();
    final String templateId = event.evaluationTemplateId.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ideathonEventWorkspaceHeader(
          event: event,
          organisationName: vm.organisationName,
        ),
        const SizedBox(height: 10),
        EventLabeledField(
          label: 'Template',
          isLast: true,
          labelWidth: _labelWidth,
          trailing: EntityCardPills.workspace(
            templateLabel,
            ContextPillSemantic.evaluationTemplate,
            () => EvaluationTemplateWorkspace.push(
              context,
              templateId,
              departmentCode: event.departmentId,
            ),
            enabled: templateId.isNotEmpty,
            icon: AppIcons.scoring,
          ),
        ),
      ],
    );
  }

  Widget _people(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _peopleGroup(
          context,
          title: 'Judges',
          users: vm.judges,
          semantic: ContextPillSemantic.judge,
          emptyLabel: 'No judges assigned.',
        ),
        const SizedBox(height: 10),
        _peopleGroup(
          context,
          title: 'Coordinators',
          users: vm.coordinators,
          semantic: ContextPillSemantic.user,
          emptyLabel: 'No coordinators assigned.',
        ),
      ],
    );
  }

  Widget _peopleGroup(
    BuildContext context, {
    required String title,
    required List<UserModel> users,
    required ContextPillSemantic semantic,
    required String emptyLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        if (users.isEmpty)
          Text(emptyLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))
        else
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: users.map((UserModel user) {
              final String id = user.userId.trim();
              final bool canOpen = id.isNotEmpty;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UserWorkspaceAvatar(
                    user: user,
                    radius: 13,
                    ringPadding: 2,
                    semantic: semantic,
                    allowHoverScale: false,
                    enabled: canOpen,
                    onTap: canOpen ? () => WorkspaceNavigator.openUser(context, id) : () {},
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      userDisplayName(user),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(growable: false),
          ),
      ],
    );
  }

  Widget _ideas(BuildContext context, List<IdeathonIdeaSnapshot> ideas) {
    if (ideas.isEmpty) {
      return const Text(
        'No ideas registered.',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ideas.map((IdeathonIdeaSnapshot snapshot) {
        final String id = snapshot.ideaId.trim();
        final String title = snapshot.ideaTitle.trim().isEmpty ? id : snapshot.ideaTitle.trim();
        return EntityCardPills.workspace(
          title,
          ContextPillSemantic.idea,
          () => WorkspaceNavigator.openIdea(context, id),
          enabled: id.isNotEmpty,
          icon: AppIcons.ideas,
        );
      }).toList(growable: false),
    );
  }

  Widget _resultPlace(
    BuildContext context, {
    required String placeLabel,
    required IconData icon,
    required Color accent,
    required EventWinnerEntry? entry,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                placeLabel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Score',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entry?.scoreLabel ?? '—',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    height: 1,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (entry == null)
          const Text(
            'Not available yet.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              EntityCardPills.workspace(
                entry.ideaTitle,
                ContextPillSemantic.idea,
                () => WorkspaceNavigator.openIdea(context, entry.ideaId),
                enabled: entry.ideaId.trim().isNotEmpty,
                icon: AppIcons.ideas,
              ),
              if (entry.teamName.trim().isNotEmpty)
                EntityCardPills.workspace(
                  entry.teamName,
                  ContextPillSemantic.team,
                  () => WorkspaceNavigator.openTeam(context, entry.teamId),
                  enabled: entry.teamId.trim().isNotEmpty,
                  icon: AppIcons.teams,
                ),
            ],
          ),
      ],
    );
  }
}
