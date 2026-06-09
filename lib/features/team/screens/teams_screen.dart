import 'package:flutter/material.dart';

import '../../../constants/app_icons.dart';
import '../../requests/faculty/team_change_workspace.dart';
import 'package:hackz/features/idea/models/idea_model.dart';
import 'package:hackz/features/payment/models/payment_model.dart';
import '../models/team_model.dart';
import '../../user/models/user_model.dart';
import '../../../shared/feedback/feedback.dart';
import '../services/faculty_teams_service.dart';
import '../../../screens/common/app_dialog_template.dart';
import '../../../screens/common/dashboard_components.dart';
import '../../../widgets/dashboard/dashboard_metric_chips.dart';
import '../widgets/team_capacity_widget.dart';
import 'team_creation_workspace.dart';
import '../widgets/team_workspace_card.dart';
import '../../../core/responsive/responsive_metric_grid.dart';
import '../../../core/responsive/responsive_helper.dart';
import 'package:hackz/core/workspace/workspace_navigator.dart';
import 'package:hackz/widgets/common/context_pill.dart';
import 'package:hackz/widgets/common/context_pill_theme.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late Future<FacultyTeamsWorkspaceData> _future;
  TeamModel? _teamChangeTarget;
  FacultyTeamInsight? _teamChangeInsight;

  @override
  void initState() {
    super.initState();
    _future = _loadTeamsData(forceRefresh: true);
  }

  Future<FacultyTeamsWorkspaceData> _loadTeamsData({bool forceRefresh = false}) =>
      FacultyTeamsService.load(widget.user, forceRefresh: forceRefresh);

  void _refresh() {
    setState(() {
      _future = _loadTeamsData(forceRefresh: true);
    });
  }

  Future<void> _openCreateTeamDialog(FacultyTeamsWorkspaceData data) async {
    if (!FacultyTeamsService.canCreateTeam(data.teams)) return;
    final result = await showTeamCreationWorkspace(
      context: context,
      currentUser: widget.user,
      existingTeams: data.teams,
      departmentStudents: data.students,
      initialTeam: null,
    );
    if (result == TeamFormDialogAction.saved && mounted) {
      _refresh();
    }
  }

  void _openTeamChangeWorkspace(TeamModel team, FacultyTeamInsight insight) {
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
      message: 'This will mark ${team.teamName} inactive and release assigned students.',
      confirmLabel: 'Disable',
      dangerConfirm: true,
    );
    if (!ok) return;
    await FacultyTeamsService.disableTeam(team);
    if (mounted) _refresh();
  }

  Future<void> _viewIdeas(FacultyTeamInsight insight) {
    return showAppDialog<void>(
      context: context,
      width: DialogWidthPreset.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _TeamIdeasPreview(insight: insight),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FacultyTeamsWorkspaceData>(
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
            departmentStudents: data.students,
            hasEvaluation:
                TeamChangeWorkspaceController.hasEvaluation(_teamChangeInsight ?? data.insightsByTeamId[_teamChangeTarget!.teamId] ??
                    FacultyTeamInsight(
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
        final canCreate = FacultyTeamsService.canCreateTeam(teams);

        return LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height;
            return SizedBox(
              width: constraints.maxWidth,
              height: viewportHeight,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _HeaderSection(),
                    const SizedBox(height: 14),
                    _SummaryGrid(data: data),
                    const SizedBox(height: 14),
                    _CreateTeamCta(
                      canCreate: canCreate,
                      teamCount: teams.length,
                      onCreate: () => _openCreateTeamDialog(data),
                    ),
                    const SizedBox(height: 14),
                    if (teams.isEmpty)
                      _EmptyTeamsState(onCreate: canCreate ? () => _openCreateTeamDialog(data) : null)
                    else
                      _TeamGrid(
                        teams: teams,
                        data: data,
                        mentorName: '${widget.user.firstName} ${widget.user.lastName}'.trim(),
                        onEdit: (team) {
                          final FacultyTeamInsight insight = data.insightsByTeamId[team.teamId] ??
                              FacultyTeamInsight(
                                team: team,
                                ideas: const <IdeaModel>[],
                                paymentStatuses: const <PaymentRecordStatus>[],
                                evaluationCount: 0,
                              );
                          _openTeamChangeWorkspace(team, insight);
                        },
                        onViewIdeas: (insight) => _viewIdeas(insight),
                        onDisable: _disableTeam,
                      ),
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Team Workspace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        SizedBox(height: 3),
        Text('Manage teams, mentoring actions, and idea submission workflow.', style: TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.data});

  final FacultyTeamsWorkspaceData data;

  @override
  Widget build(BuildContext context) {
    return ResponsiveMetricGrid(
      chips: <DashboardMetricChipData>[
        DashboardMetricChipData.ratio(
          label: 'Total Teams',
          primary: '${data.teams.length}',
          secondary: '${FacultyTeamsService.maxTeamsPerFaculty}',
          subtitle: 'Teams created',
          color: const Color(0xFF6A38FF),
          icon: AppIcons.teams,
        ),
        DashboardMetricChipData.single(
          label: 'Total Students',
          value: '${data.totalStudents}',
          color: const Color(0xFF0EA5E9),
          icon: AppIcons.student,
        ),
        DashboardMetricChipData.single(
          label: 'Active Ideas',
          value: '${data.activeIdeas}',
          color: const Color(0xFFEA580C),
          icon: AppIcons.ideas,
        ),
        DashboardMetricChipData.single(
          label: 'Team Capacity',
          value: FacultyTeamsService.capacityMessage(data.teams.length),
          color: const Color(0xFF16A34A),
          icon: AppIcons.verification,
        ),
      ],
    );
  }
}

class _CreateTeamCta extends StatelessWidget {
  const _CreateTeamCta({
    required this.canCreate,
    required this.teamCount,
    required this.onCreate,
  });

  final bool canCreate;
  final int teamCount;
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
                    Text('Build a compact 2-4 student team for idea submission.', style: TextStyle(color: Color(0xFF64748B))),
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
              TeamCapacityWidget(teamCount: teamCount, maxTeams: FacultyTeamsService.maxTeamsPerFaculty),
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

class _TeamGrid extends StatelessWidget {
  const _TeamGrid({
    required this.teams,
    required this.data,
    required this.mentorName,
    required this.onEdit,
    required this.onViewIdeas,
    required this.onDisable,
  });

  final List<TeamModel> teams;
  final FacultyTeamsWorkspaceData data;
  final String mentorName;
  final ValueChanged<TeamModel> onEdit;
  final ValueChanged<FacultyTeamInsight> onViewIdeas;
  final ValueChanged<TeamModel> onDisable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveHelper.useDashboardMultiColumn(context) ? 2 : 1;
        final gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: teams.map((team) {
            final insight = data.insightsByTeamId[team.teamId] ??
                FacultyTeamInsight(
                  team: team,
                  ideas: const <IdeaModel>[],
                  paymentStatuses: const <PaymentRecordStatus>[],
                  evaluationCount: 0,
                );
            return SizedBox(
              width: width,
              child: TeamWorkspaceCard(
                team: team,
                insight: insight,
                mentorName: mentorName,
                studentNamesById: data.studentNamesById,
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
            const Text('Select students, assign yourself as mentor, and start the idea submission workflow.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onCreate, icon: const Icon(AppIcons.add), label: const Text('Create Team')),
          ],
        ),
      ),
    );
  }
}

class _TeamIdeasPreview extends StatelessWidget {
  const _TeamIdeasPreview({required this.insight});

  final FacultyTeamInsight insight;

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
                      WorkspaceNavigator.openIdea(context, ideaId);
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

