import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../requests/faculty/screens/team_change_workspace.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../services/teams_workspace_service.dart';
import '../services/team_service.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import 'team_creation_workspace.dart';
import '../widgets/team_metrics_row.dart';
import '../widgets/team_workspace_card.dart';
import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_helper.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/core/ui/common/context_pill.dart';
import 'package:hackz/core/ui/common/context_pill_theme.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late Future<TeamsWorkspaceData> _future;
  TeamModel? _teamChangeTarget;
  TeamWorkspaceInsight? _teamChangeInsight;

  @override
  void initState() {
    super.initState();
    _future = _loadTeamsData(forceRefresh: true);
  }

  Future<TeamsWorkspaceData> _loadTeamsData({bool forceRefresh = false}) =>
      TeamsWorkspaceService.load(widget.user, forceRefresh: forceRefresh);

  void _refresh() {
    setState(() {
      _future = _loadTeamsData(forceRefresh: true);
    });
  }

  Future<void> _openCreateTeamDialog(TeamsWorkspaceData data) async {
    if (!TeamsWorkspaceService.canCreateTeam(data.teams, actor: widget.user)) return;
    final result = await showTeamCreationWorkspace(
      context: context,
      currentUser: widget.user,
      existingTeams: data.teams,
      departmentTeamMembers: data.teamMembers,
      initialTeam: null,
    );
    if (result == TeamFormDialogAction.saved && mounted) {
      _refresh();
    }
  }

  void _openTeamChangeWorkspace(TeamModel team, TeamWorkspaceInsight insight) {
    setState(() {
      _teamChangeTarget = team;
      _teamChangeInsight = insight;
    });
  }

  void _closeTeamChangeWorkspace({bool refresh = false}) {
    setState(() {
      _teamChangeTarget = null;
      _teamChangeInsight = null;
    });
    if (refresh) _refresh();
  }

  Future<void> _disableTeam(TeamModel team) async {
    final bool ok = await FeedbackService.showConfirmation(
      context,
      title: 'Disable team?',
      message: 'This will mark ${team.teamName} inactive and release assigned team members.',
      confirmLabel: 'Disable',
      dangerConfirm: true,
    );
    if (!ok) return;
    await TeamsWorkspaceService.disableTeam(team, actor: widget.user);
    if (mounted) _refresh();
  }

  Future<void> _viewIdeas(TeamWorkspaceInsight insight) {
    return showAppDialog<void>(
      context: context,
      width: DialogWidthPreset.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _TeamIdeasPreview(insight: insight, user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TeamsWorkspaceData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load teams: ${snapshot.error}');
        }
        final data = snapshot.data;
        if (data == null) return const Center(child: Text('No team data available.'));

        if (_teamChangeTarget != null) {
          return TeamChangeWorkspace(
            faculty: widget.user,
            team: _teamChangeTarget!,
            departmentTeamMembers: data.teamMembers,
            hasEvaluation:
                TeamChangeWorkspaceController.hasEvaluation(_teamChangeInsight ?? data.insightsByTeamId[_teamChangeTarget!.teamId] ??
                    TeamWorkspaceInsight(
                      team: _teamChangeTarget!,
                      ideas: const <IdeaModel>[],
                      paymentStatuses: const <PaymentRecordStatus>[],
                      evaluationCount: 0,
                    )),
            embedded: true,
            onBack: () => _closeTeamChangeWorkspace(),
            onSubmitted: () => _closeTeamChangeWorkspace(refresh: true),
          );
        }

        final teams = data.teams;
        final canCreate = TeamsWorkspaceService.canCreateTeam(teams, actor: widget.user);
        final bool mobile = ResponsiveHelper.isMobile(context);
        final Map<String, UserModel> membersById = <String, UserModel>{
          for (final UserModel member in data.teamMembers) member.userId: member,
        };

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool hasBoundedHeight = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final Widget metrics = TeamMetricsRow(
              teamCount: teams.length,
              totalTeamMembers: data.totalTeamMembers,
              activeIdeas: data.activeIdeas,
              spacing: mobile ? 8 : 10,
              runSpacing: mobile ? 8 : 10,
            );
            final VoidCallback? onCreate = canCreate ? () => _openCreateTeamDialog(data) : null;
            final Widget teamList = teams.isEmpty
                ? _EmptyTeamsState(onCreate: onCreate)
                : _TeamList(
                    teams: teams,
                    data: data,
                    membersById: membersById,
                    onEdit: (TeamModel team) {
                      if (!TeamService.canManageTeam(widget.user, team)) return;
                      final TeamWorkspaceInsight insight = data.insightsByTeamId[team.teamId] ??
                          TeamWorkspaceInsight(
                            team: team,
                            ideas: const <IdeaModel>[],
                            paymentStatuses: const <PaymentRecordStatus>[],
                            evaluationCount: 0,
                          );
                      _openTeamChangeWorkspace(team, insight);
                    },
                    onViewIdeas: _viewIdeas,
                    onDisable: _disableTeam,
                  );

            if (mobile) {
              final Widget header = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _MobileCreateBar(
                    onCreate: onCreate,
                  ),
                  const SizedBox(height: 8),
                  metrics,
                  const SizedBox(height: 8),
                ],
              );

              if (!hasBoundedHeight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    header,
                    SizedBox(height: 480, child: teamList),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  header,
                  Expanded(child: teamList),
                ],
              );
            }

            final viewportHeight = hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            return SizedBox(
              width: constraints.maxWidth,
              height: viewportHeight,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    metrics,
                    const SizedBox(height: 14),
                    _CreateTeamCta(
                      canCreate: canCreate,
                      onCreate: () => _openCreateTeamDialog(data),
                    ),
                    const SizedBox(height: 14),
                    teamList,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MobileCreateBar extends StatelessWidget {
  const _MobileCreateBar({
    required this.onCreate,
  });

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(AppIcons.add, size: 16),
            label: const Text('Create Team'),
            style: MobileToolbarButtonStyles.filled(compact: true),
          ),
        ),
      ],
    );
  }
}

class _CreateTeamCta extends StatelessWidget {
  const _CreateTeamCta({
    required this.canCreate,
    required this.onCreate,
  });

  final bool canCreate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = const Row(
            children: <Widget>[
              Icon(AppIcons.teams, color: Color(0xFF6A38FF), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Create an innovation team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Build a compact 2-4 member team for idea submission.', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed: canCreate ? onCreate : null,
                icon: const Icon(AppIcons.add, size: 16),
                label: const Text('Create Team'),
              ),
            ],
          );
          if (ResponsiveHelper.isMobile(context) || constraints.maxWidth < ResponsiveBreakpoints.tablet) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[details, const SizedBox(height: 12), actions],
            );
          }
          return Row(
            children: <Widget>[Expanded(child: details), const SizedBox(width: 12), actions],
          );
        },
      ),
    );
  }
}

class _TeamList extends StatelessWidget {
  const _TeamList({
    required this.teams,
    required this.data,
    required this.membersById,
    required this.onEdit,
    required this.onViewIdeas,
    required this.onDisable,
  });

  final List<TeamModel> teams;
  final TeamsWorkspaceData data;
  final Map<String, UserModel> membersById;
  final ValueChanged<TeamModel> onEdit;
  final ValueChanged<TeamWorkspaceInsight> onViewIdeas;
  final ValueChanged<TeamModel> onDisable;

  TeamWorkspaceInsight _insightFor(TeamModel team) {
    return data.insightsByTeamId[team.teamId] ??
        TeamWorkspaceInsight(
          team: team,
          ideas: const <IdeaModel>[],
          paymentStatuses: const <PaymentRecordStatus>[],
          evaluationCount: 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bool mobile = ResponsiveHelper.isMobile(context);

    if (mobile) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: teams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final TeamModel team = teams[index];
          final TeamWorkspaceInsight insight = _insightFor(team);
          return TeamWorkspaceCard(
            team: team,
            insight: insight,
            membersById: membersById,
            memberNamesById: data.memberNamesById,
            onEdit: () => onEdit(team),
            onViewIdeas: () => onViewIdeas(insight),
            onDisable: () => onDisable(team),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = ResponsiveHelper.useDashboardMultiColumn(context) ? 2 : 1;
        const double gap = 14;
        final double width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: teams.map((TeamModel team) {
            final TeamWorkspaceInsight insight = _insightFor(team);
            return SizedBox(
              width: width,
              child: TeamWorkspaceCard(
                team: team,
                insight: insight,
                membersById: membersById,
                memberNamesById: data.memberNamesById,
                onEdit: () => onEdit(team),
                onViewIdeas: () => onViewIdeas(insight),
                onDisable: () => onDisable(team),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _EmptyTeamsState extends StatelessWidget {
  const _EmptyTeamsState({required this.onCreate});

  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
              child: const Icon(AppIcons.teams, size: 34, color: Color(0xFF6A38FF)),
            ),
            const SizedBox(height: 14),
            const Text('Create your first innovation team', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Select team members, assign yourself as Team Leader, and start the idea submission workflow.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(AppIcons.add), label: const Text('Create Team')),
          ],
        ),
      ),
    );
  }
}

class _TeamIdeasPreview extends StatelessWidget {
  const _TeamIdeasPreview({required this.insight, required this.user});

  final TeamWorkspaceInsight insight;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final List<IdeaModel> ideas = List<IdeaModel>.from(insight.ideas)
      ..sort((IdeaModel a, IdeaModel b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '${insight.team.teamName} · Ideas',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        if (ideas.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No ideas submitted for this team yet.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: ideas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (BuildContext context, int index) {
                final IdeaModel idea = ideas[index];
                final String title = idea.ideaTitle.trim().isEmpty ? 'Untitled Idea' : idea.ideaTitle.trim();
                final String ideaId = idea.ideaId.trim();
                if (ideaId.isEmpty) {
                  return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)));
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: ContextPill(
                    label: title,
                    semantic: ContextPillSemantic.idea,
                    icon: AppIcons.ideas,
                    onTap: () {
                      Navigator.of(context).pop();
                      WorkspaceNavigator.openIdea(context, ideaId, actor: user);
                    },
                    compact: true,
                    expandWidth: true,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ),
      ],
    );
  }
}

